class Homestead
  def Homestead.configure(config, settings)

    # Smphet The VM Provider
    ENV['VAGRANT_DEFAULT_PROVIDER'] = settings["provider"] ||= "virtualbox"

    # Configure The Box
    config.vm.box = "laravel/homestead"
    config.vm.box_version = "0.3.3"

    # Configure A Private Network IP
    config.vm.network :private_network, ip: settings["ip"] ||= "192.168.10.10"

    # Configure A Few VirtualBox Settings
    config.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "2048"]
      vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "1"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
    end

    # Configure A Few VMware Settings
    ["vmware_fusion", "vmware_workstation"].each do |vmware|
      config.vm.provider vmware do |v|
        v.vmx["displayName"] = "homestead"
        v.vmx["memsize"] = settings["memory"] ||= 2048
        v.vmx["numvcpus"] = settings["cpus"] ||= 1
        v.vmx["guestOS"] = "ubuntu-64"
      end
    end

    # Configure Port Forwarding To The Box
    config.vm.network "forwarded_port", guest: 80, host: 8000
    config.vm.network "forwarded_port", guest: 443, host: 44300
    config.vm.network "forwarded_port", guest: 3306, host: 33060
    config.vm.network "forwarded_port", guest: 5432, host: 54320
    config.vm.network "forwarded_port", guest: 35729, host: 35729

    # Add Custom Ports From Configuration
    if settings.has_key?("ports")
      settings["ports"].each do |port|
        config.vm.network "forwarded_port", guest: port["guest"] || port["to"], host: port["host"] || port["send"], protocol: port["protocol"] ||= "tcp"
      end
    end

    config.vm.provision "shell", run: "always" do |s|
      s.inline = "service beanstalkd start"
    end

    # Configure The Public Key For SSH Access
    if settings.include? 'authorize'
      config.vm.provision "shell" do |s|
        s.inline = "echo $1 | grep -xq \"$1\" /home/vagrant/.ssh/authorized_keys || echo $1 | tee -a /home/vagrant/.ssh/authorized_keys"
        s.args = [File.read(File.expand_path(settings["authorize"]))]
      end
    end

    # Copy The SSH Private Keys To The Box
    if settings.include? 'keys'
      settings["keys"].each do |key|
        config.vm.provision "shell" do |s|
          s.privileged = false
          s.inline = "echo \"$1\" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2"
          s.args = [File.read(File.expand_path(key)), key.split('/').last]
        end
      end
    end

    # Register All Of The Configured Shared Folders
    settings["folders"].each do |folder|
      config.vm.synced_folder folder["map"], folder["to"], type: folder["type"] ||= nil
    end

    # Install All The Configured Nginx Sites
    settings["sites"].each do |site|
      config.vm.provision "shell" do |s|
          if (site.has_key?("hhvm") && site["hhvm"])
            s.inline = "bash /vagrant/scripts/serve-hhvm.sh $1 \"$2\" $3"
            s.args = [site["map"], site["to"], site["port"] ||= "80"]
          else
            s.inline = "bash /vagrant/scripts/serve.sh $1 \"$2\" $3"
            s.args = [site["map"], site["to"], site["port"] ||= "80"]
          end
      end
    end

    # Configure All Of The Server Environment Variables
    if settings.has_key?("variables")
      settings["variables"].each do |var|
        config.vm.provision "shell" do |s|
          s.inline = "echo \"\nenv[$1] = '$2'\" >> /etc/php5/fpm/php-fpm.conf"
          s.args = [var["key"], var["value"]]
        end

        config.vm.provision "shell" do |s|
            s.inline = "echo \"\n#Set Homestead environment variable\nexport $1=$2\" >> /home/vagrant/.profile"
            s.args = [var["key"], var["value"]]
        end
      end

      config.vm.provision "shell" do |s|
        s.inline = "service php5-fpm restart"
      end
    end

    # Copy The Bash Aliases
    config.vm.provision "shell" do |s|
      s.inline = "bash /vagrant/scripts/addons.sh"
    end

    if settings["mailcatcher"] == true
      config.vm.provision "shell" do |s|
        s.inline = "bash /vagrant/scripts/mailcatcher.sh"
      end
    end


    if settings["selenium"] == true
      config.vm.provision "shell" do |s|
        s.inline = "bash /vagrant/scripts/seleniuminstall.sh"
      end
    end

    config.vm.provision "shell", run: "always" do |s|
      s.inline = "composer self-update"
    end

    if settings["npm_install"] == true
        config.vm.provision "shell" do |s|
            s.inline = "cp /home/vagrant/Code/package.json /home/vagrant/package.json && cd /home/vagrant/ && sudo npm install"
        end
    end

    if settings["bower_install"] == true
        config.vm.provision "shell" do |s|
            s.inline = "cd /home/vagrant/Code/ && bower install --allow-root"
        end
    end

    if settings["composer"] == true
        config.vm.provision "shell", run: "always" do |s|
            s.inline = "cd /home/vagrant/Code/ && composer install"
        end
    end

    if settings["laravel"] == true
        config.vm.provision "shell" do |s|
            s.inline = "cd /home/vagrant/Code/ && cp -n .env.local .env && php artisan key:generate"
        end

        config.vm.provision "shell", run: "always" do |s|
            s.inline = "cd /home/vagrant/Code/ && php artisan migrate --force"
        end

        config.vm.provision "shell" do |s|
          s.inline = "cp /vagrant/scripts/laravel-worker.conf /etc/supervisor/conf.d/laravel-worker.conf"
        end
    end

    if settings["wordpress"] == true
        config.vm.provision "shell" do |s|
            s.inline = "cd /home/vagrant/Code/ && cp wp-config.local public/wp-config.php"
        end
    end

    if settings["mailcatcher"] == true
        config.vm.provision "shell", run: "always" do |s|
            s.inline = "mailcatcher --http-ip=192.168.57.10"
        end
    end

    if settings["run_gulp"] == true
      config.vm.provision "shell", run: "always" do |s|
        s.inline = "cd /home/vagrant/Code/ && gulp"
      end
    end

    config.vm.provision "shell", run: "always" do |s|
        s.privileged = false;
        s.inline = "cd /home/vagrant/Code/ && npm run build && PRODUCTION=true pm2 start /home/vagrant/Code/start.js"
    end

    # Configure Blackfire.io
    if settings.has_key?("blackfire")
      config.vm.provision "shell" do |s|
        s.path = "./scripts/blackfire.sh"
        s.args = [settings["blackfire"][0]["id"], settings["blackfire"][0]["token"]]
      end
    end
  end
end
