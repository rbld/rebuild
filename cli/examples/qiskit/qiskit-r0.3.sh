#!/bin/bash -ex

API_TOKEN=yourtoken

wget -c https://repo.continuum.io/archive/Anaconda3-4.4.0-Linux-x86_64.sh
chmod +x Anaconda3-4.4.0-Linux-x86_64.sh

echo "APItoken = \"$API_TOKEN\"" > Qconfig.py
echo "config = {'url':'https://quantumexperience.ng.bluemix.net/api'}" >> Qconfig.py

rbld create --base ubuntu:16.04 qiskit
rbld modify qiskit:initial -- "sudo apt-get update"
rbld modify qiskit:initial -- "sudo apt-get install -y make git python python3-pip" 
rbld modify qiskit:initial -- "sudo bash Anaconda3-4.4.0-Linux-x86_64.sh -b -p /anaconda3" 
rbld modify qiskit:initial -- "echo export PATH=/anaconda3/bin:\\\$PATH | sudo tee -a /rebuild/rebuild.rc > /dev/null"
rbld modify qiskit:initial -- "sudo git clone https://github.com/IBM/qiskit-sdk-py.git /Qiskit"
rbld modify qiskit:initial -- "sudo chmod 777 -R /Qiskit"
rbld modify qiskit:initial -- "sudo pip install IBMQuantumExperience"
rbld modify qiskit:initial -- "echo "c.NotebookApp.ip  = \\\''\$(hostname -i)'\\\'" | sudo tee /anaconda3/etc/jupyter/jupyter_notebook_config.py"
rbld commit qiskit --tag r0.3
