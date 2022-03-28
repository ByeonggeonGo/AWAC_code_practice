import gym
import torch
import pickle

from src.Learner.AWAC import AWAC
from src.Learner.DQN import DQN
from src.Learner.Random import DiscreteRandomAgent
from src.nn.MLP import MLP
from src.utils.memory import ReplayMemory
from src.utils.train_utils import prepare_training_inputs

import matplotlib.pyplot as plt
from glob import glob
import os

from flask import Blueprint, stream_with_context, request, Response

bp = Blueprint('main', __name__, url_prefix='/')
@bp.route('/')
def index():
    return 'hi'

@bp.route('/data')
def getdata():
    return str("pred")

@bp.route('/modelfit')
def modelfit():
    # Do the training
    test = making_offline_dataset()

    return str(test)

@bp.route('/train')
def train_offline_data():
    def generate():
        memory = making_offline_dataset()
        agent = make_agent()
        batch_size = 1024
        n_updates = 8000
        fit_device = 'cuda' if torch.cuda.is_available() else 'cpu'

        agent.to(fit_device)
        critic_losses, actor_losses = [], []
        for i in range(n_updates):
            if i % 1000 == 0:
                print("fitting [{}] / [{}]".format(i, n_updates))
            sampled_exps = memory.sample(batch_size)
            s, a, r, ns, done = prepare_training_inputs(sampled_exps, 
                                                        device=fit_device)    
            critic_loss = agent.update_critic(s,a,r,ns,done)
            actor_loss = agent.update_actor(s,a)
            critic_losses.append(critic_loss.detach())
            actor_losses.append(actor_loss.detach())
            yield str(actor_losses)
    return Response(stream_with_context(generate()))











def making_offline_dataset():
    make_new_memory = False
    path = os.getcwd()
    DB_path = os.path.join(path,"data","DB")
    save_memory_name = os.path.join(DB_path,"memory.p")
    pretrained_dqn_agent_path = os.path.join(path,"dqn_agent.pt")
    ############################
    ## making offline dataset ##
    ############################
    if make_new_memory:
        gamma = 0.9
        memory_size = 500000
        env = gym.make('CartPole-v1')
        memory = ReplayMemory(memory_size)

        use_expert = True
        if use_expert:    
            qnet = MLP(4, 2, num_neurons=[128])
            qnet_target = MLP(4, 2, num_neurons=[128])
            dqn = DQN(4, 1, qnet=qnet,qnet_target=qnet_target, lr=1e-4, gamma=gamma, epsilon=1.0)
            state_dict = torch.load(pretrained_dqn_agent_path)
            
            # make trained agent slightly dumb
            # to simulate the realistic scenario where we don't have 'perfect' policy
            # but good enough policy.
            
            state_dict['epsilon'] = dqn.epsilon * .4 
            dqn.load_state_dict(state_dict)    
            offline_agent = dqn
            offline_budget = 50
        else:
            offline_agent = DiscreteRandomAgent(2)
            offline_budget = 300

        online_budget = offline_budget
        cum_rs = []
        for n_epi in range(offline_budget):
            s = env.reset()
            cum_r = 0

            while True:
                s = torch.tensor((s,), dtype=torch.float)
                a = offline_agent.get_action(s)
                ns, r, done, info = env.step(a)

                experience = (s,
                            torch.tensor(a).view(1, 1),
                            torch.tensor(r).view(1, 1),
                            torch.tensor(ns).view(1, 4),
                            torch.tensor(done).view(1, 1))
                memory.push(experience)

                s = ns
                cum_r += 1
                if done:
                    cum_rs.append(cum_r)
                    break
        pickle.dump(memory, open(save_memory_name, "wb"))     #momory저장하기
    else:
        momory = pickle.load(open(save_memory_name, "rb"))    #momory불러오기

    print("ok")
    return momory


def make_agent():

    gamma = 0.9
    qnet = MLP(4, 2, 
            num_neurons=[128,128], 
            out_act='ReLU')
    qnet_target = MLP(4, 2, 
                    num_neurons=[128,128], 
                    out_act='ReLU')
    pi = MLP(4, 2, num_neurons=[128,64])
    use_adv = True

    agent = AWAC(critic=qnet, 
                critic_target=qnet_target,
                actor=pi, 
                gamma=gamma, 
                lam=1.0, 
                num_action_samples=10,
                use_adv=use_adv)

    return agent


