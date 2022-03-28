from flask import Blueprint
from glob import glob
import os
import pandas as pd
import tensorflow as tf
from tensorflow import keras
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
import numpy as np
from sklearn.datasets import load_iris

# Train model.
iris_dataset = load_iris()


def train(model, x, y):
  with tf.GradientTape() as t:
    # Trainable variables are automatically tracked by GradientTape
    current_loss = loss(y_true=y,y_pred=model(x, training=True))

  # Use GradientTape to calculate the gradients with respect to W and b
  grads= t.gradient(current_loss, model.trainable_variables)
  
  # Subtract the gradient scaled by the learning rate
  optimizer.apply_gradients(zip(grads, model.trainable_variables))

def training_loop(model, x, y, validset = None):
    # Keep results for plotting
    train_loss_results = []
    val_loss_results = []
    for epoch in epochs:
        # Update the model with the single giant batch
        train(model, x, y)

        # Track this before I update
        if validset == None:
            current_loss = loss(y,model(x))
            print("Epoch %2d: loss=%2.5f" %
                (epoch, current_loss))
        else:
            x_val = validset[0]
            y_val = validset[1]

            current_loss = loss(y_true=y,y_pred=model(x))
            valid_loss = loss(y_true=y_val,y_pred=model(x_val))
            print("Epoch %2d: loss=%2.5f  val_loss=%2.5f" %
                (epoch, current_loss, valid_loss))
            # save loss history
            train_loss_results.append(current_loss.numpy())
            val_loss_results.append(valid_loss.numpy())
    return train_loss_results,val_loss_results
            


path = os.getcwd()
csv_list = sorted(glob(os.path.join(path,"ml_flask_api_server","data","DB","*.csv")))
data = pd.read_csv(csv_list[1])
trainset, testset = train_test_split(data,test_size=0.2,shuffle=True)

scaler = MinMaxScaler()
X_train = trainset.values[:,:-1]
X_train = scaler.fit_transform(X_train)
y_train = trainset.values[:,-1]
# y_train = pd.get_dummies(trainset.values[:,-1]).values
y_train = tf.convert_to_tensor(y_train, dtype=tf.float32)

X_test = testset.values[:,:-1]
X_test = scaler.transform(X_test)
y_test = testset.values[:,-1]
# y_test = pd.get_dummies(testset.values[:,-1]).values
y_test = tf.convert_to_tensor(y_test, dtype=tf.float32)


#params
input_shape = 4
output_shape = 3
lr = 0.03
act_function = 'relu'
outlayer_act_function = 'softmax'
category = "classification"
#optimizer
optimizer = keras.optimizers.SGD(learning_rate=lr)

# #loss function
loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True)


num_perceptron_layer1 = 8
num_perceptron_layer2 = 16
num_perceptron_layer3 = 32
num_perceptron_layer4 = 16
num_perceptron_layer5 = 8
num_perceptron_out = output_shape

num_perceptron_list = [
    num_perceptron_layer1,
    num_perceptron_layer2,
    num_perceptron_layer3,
    num_perceptron_layer4,
    num_perceptron_layer5,
    num_perceptron_out,
    ]

# model definition
inputs = tf.keras.Input(shape=input_shape)
for i in range(len(num_perceptron_list)):
    n_percep = num_perceptron_list[i]
    if i == 0:
        x = keras.layers.Dense(n_percep, activation= act_function)(inputs)

    elif  i != 0 and n_percep != 0 and i != len(num_perceptron_list)-1:
        x = keras.layers.Dense(n_percep, activation= act_function)(x)

    elif  i == len(num_perceptron_list)-1:
        x = keras.layers.Dense(n_percep,)(x)#activation= outlayer_act_function)(x)

    else: pass

dense_model = tf.keras.Model(name="model_1",inputs=inputs, outputs=x)
# dense_model.summary()


# Define a training loop
epochs = range(300)    
# print(y_train[:5],dense_model(X_train[:5]))
# print(loss(y_train[:5],dense_model(X_train[:5])))
# print(loss(y_train[:5], dense_model(X_train[:5])))
# Do the training
# training_loop(dense_model, X_train, y_train,validset=[X_test,y_test])


# from sklearn import metrics
# y_pred_test = dense_model(X_test).numpy()
# y_pred_test = np.argmax(y_pred_test, axis=1).tolist()
# # y_test = np.argmax(y_test, axis=1).tolist()

# # Print the confusion matrix
# print(metrics.confusion_matrix(y_test, y_pred_test))



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
    train_loss, val_loss = training_loop(dense_model, X_train, y_train,validset=[X_test,y_test])

    return str(train_loss)




