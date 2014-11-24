#!/bin/bash
if [ ! -d /home/vagrant/tmp ]; then
    sudo apt-get install -qy curl
    cd /home/vagrant
    su vagrant -c 'curl -s https://install.meteor.com | sed s/--progress-bar/-s/ | sh'
    su vagrant -c 'meteor create tmp'
    cd tmp
    echo "Creating empty Mongo stuff to fix permissions..."
    su vagrant -c 'meteor' &
    sleep 60
    ps ax | grep meteor | awk '{print $1;}' | head -n -1 | xargs kill
    #su vagrant -c 'meteor remove autopublish insecure'
    echo "Configuring permission fix..."
    echo "sudo mount --bind /home/vagrant/tmp/.meteor/local/ /vagrant/kapuut/.meteor/local/" >> /home/vagrant/.bashrc
    echo "Making life easier..."
    echo "cd /vagrant/kapuut" >> /home/vagrant/.bashrc
    echo "Done!"
fi
