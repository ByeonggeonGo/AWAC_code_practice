import gym
import torch
import pickle

from src.Learner.AWAC import AWAC
from src.Learner.DQN import DQN
from src.Learner.Random import DiscreteRandomAgent
from src.nn.MLP import MLP
from src.utils.memory import ReplayMemory
from src.utils.train_utils import prepare_training_inputs

from glob import glob
import os

from flask import Blueprint, stream_with_context, request, Response, jsonify

bp = Blueprint('main', __name__, url_prefix='/')
@bp.route('/')
def index():
    return str('hi')

@bp.route('/check_offlinedataset')
def check_dataset():
    path = os.getcwd()
    data_list = sorted(glob(os.path.join(path,"data","DB","*")))
    file_list = {}
    for i,val in enumerate(data_list):
        file_list[i] = os.path.basename(val)
    return jsonify(file_list)

@bp.route('/check_agent_list')
def check_agentlist():
    path = os.getcwd()
    data_list = sorted(glob(os.path.join(path,"data","agent","*")))
    file_list = {}
    for i,val in enumerate(data_list):
        file_list[i] = os.path.basename(val)
    return jsonify(file_list)

@bp.route('/offline_train')
def train_offline_data():
    # query string params  = batch_size, n_updates,name_of_trained_model
    # http://192.168.0.108:51212/offline_train?batch_size=1024&n_updates=500&name_of_trained_model=test
    def generate():
        batch_size = int(request.args.get('batch_size'))
        n_updates = int(request.args.get('n_updates'))
        name_of_trained_model = request.args.get('name_of_trained_model')
        #
        path = os.getcwd()
        agent_path = os.path.join(path,"data","agent")
        save_agent_name = os.path.join(agent_path,f"{name_of_trained_model}.p")
        #
        memory = making_offline_dataset()
        agent = make_agent()
        
        
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
            yield str([actor_loss,critic_loss])
            # yield Response(str([actor_loss,critic_loss]))
        pickle.dump(agent, open(save_agent_name, "wb"))
        
    return Response(stream_with_context(generate()))

@bp.route('/online_train')
def train_online():
    # query string params  = batch_size, num_runs,name_of_target_model, name_of_updated_model,name_of_memory, name_of_updated_memory,
    # http://192.168.0.108:51212/online_train?batch_size=1024&num_runs=500&name_of_target_model=test&name_of_updated_model=agent_test&name_of_memory=memory&name_of_updated_memory=memory2
    def generate():

        batch_size = int(request.args.get('batch_size'))
        num_runs = int(request.args.get('num_runs'))
        name_of_target_model = request.args.get('name_of_target_model')
        name_of_updated_model = request.args.get('name_of_updated_model')
        name_of_memory = request.args.get('name_of_memory')
        name_of_updated_memory = request.args.get('name_of_updated_memory')

        #
        path = os.getcwd()
        DB_path = os.path.join(path,"data","DB")
        memory_name = os.path.join(DB_path,f"{name_of_memory}.p")
        save_memory_name = os.path.join(DB_path,f"{name_of_updated_memory}.p")
        # agent_list = sorted(glob(os.path.join(path,"data","agent","*")))
        agent_path = os.path.join(path,"data","agent")
        agent = pickle.load(open(os.path.join(agent_path,f"{name_of_target_model}.p"), "rb"))
        save_agent_name = os.path.join(agent_path,f"{name_of_updated_model}.p")
        #
        memory = pickle.load(open(memory_name, "rb"))
        
        
        #
        env = gym.make('CartPole-v1')
        fit_device = 'cuda' if torch.cuda.is_available() else 'cpu'
        agent.to(fit_device)
        #
        awac_cum_rs = []
        critic_losses = []
        actor_losses = []
        for n_epi in range(num_runs):
            s = env.reset()
            cum_r = 0

            #어떠한 성능 기준치 이상일경우 카운트되도록
            while True:
                s = torch.tensor((s,), dtype=torch.float)
                a = int(agent.get_action(s).squeeze())
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
                    awac_cum_rs.append(cum_r)
                    break
            if len(memory) >= batch_size:
                #전체데이터를 사용하는 것이 아니라 샘플링을 통해 사용(offline data도 포함되어 있는 상태)
                sampled_exps = memory.sample(batch_size)
                _s, _a, _r, _ns, _done = prepare_training_inputs(sampled_exps, device=fit_device)
                critic_loss = agent.update_critic(_s,_a,_r,_ns,_done)
                actor_loss = agent.update_actor(_s,_a)
                critic_losses.append(critic_loss.detach())
                actor_losses.append(actor_loss.detach())
                yield str([actor_loss,critic_loss])

        pickle.dump(memory, open(save_memory_name, "wb"))
        pickle.dump(agent, open(save_agent_name, "wb"))   
        
    return Response(stream_with_context(generate()))


@bp.route('/check_agent_perf')
def check_agent_perf():
    # query string params  = agent_name
    # http://192.168.0.108:51212/check_agent_perf?agent_name=test
    def generate():
        path = os.getcwd()
        agent_path = os.path.join(path,"data","agent")
        agent_name = request.args.get('agent_name')
        agent = pickle.load(open(os.path.join(agent_path,f"{agent_name}.p"), "rb"))



        env = gym.make('CartPole-v1')
        fit_device = 'cuda' if torch.cuda.is_available() else 'cpu'
        agent.to(fit_device)


        num_runs = 1000
        awac_cum_rs = []
        for n_epi in range(num_runs):
            s = env.reset()
            cum_r = 0

            #어떠한 성능 기준치 이상일경우 카운트되도록
            while True:
                s = torch.tensor((s,), dtype=torch.float)
                a = int(agent.get_action(s).squeeze())
                ns, r, done, info = env.step(a)

                s = ns
                cum_r += 1
                if done:
                    awac_cum_rs.append(cum_r)
                    yield str([cum_r])
                    break
        
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


