# About this Repo

This repository holds the docker-compose configuration intended to run a 
MODX3 development environment, from the basic infrastructure needed, to 
the git life cycle, all the needed components to get you up and running
developing modX extras.

## Prerequisites
1. Make sure you have the latest [docker](https://www.docker.com/) and 
   [docker-compose](https://docs.docker.com/compose/install/) installed 
2. After installing both components, make sure your docker instance is 
   running by clicking the docker system try icon => dashboard, this 
   should popup the docker dashboard, and you can check if the instance
   is running in the bottom left corner, if everything is correct, it should
   read "Docker running", with a green button ath the left side of the text.
3. For local development you'll need to a set of certs, those files are already
   part of the current repo inside the certs folder.  
   If you NEED to generate the ssl selfsigned 
   certificates, [here is a guide on how to do so](https://medium.com/the-new-control-plane/generating-self-signed-certificates-on-windows-7812a600c2d8)
   and place the `ssl.crt` and `ssl.key` files inside the certs folder.
4. Follow the wsl installation guide from the [microsoft site](https://docs.microsoft.com/en-us/windows/wsl/install-win10#manual-installation-steps)
   1. Make sure to select the plain 'Ubuntu' installation
   2. Follow the manual until you reach the following message  
   `CONGRATULATIONS! You've successfully installed and set up a Linux distribution that is completely integrated with your Windows operating system!`  
5. Go to Docker -> dashboard -> settings -> resources, and check that your new ubuntu image is listed, the click the switch next to it, and we'll be ready to go!


## Using this image
Once you run the image, the current html and mysql folders are going to get 
populated with all the files for modx installation as well as mysql system files.

1. Configure environment variables: Inside the docker-compose.yml 
   file your can find the different values that can be configured for the images.  
   You need to look for the `MODX_SERVER_ROUTE` key, and update the ip address with the one assigned to your ubuntu instance, for this go to ubuntu and type
   `ifconfig`  
   Also make sure the routes assigned for `volumes` are set up correctly, an example of such route could be `~/development/modxBasicExtra/html:/var/www/html`
   
2. Build the containers
```sh
docker-compose build
```

3. Run the containers
```sh
docker-compose up
```

4. The first time you'll run the container it'll take some time while it 
   downloads and installs the different components, at the end you should see
   a line similar to this one
```sh
web_1  | [Thu Jan 14 13:27:32.027113 2021] [core:notice] [pid 1] AH00094: Command line: 'apache2 -D FOREGROUND'
```   

5. Check that everything is working as expected, for this open `https://MODX_SERVER_ROUTE/`
replace the x's with your actual ip address.

## Developing with this image

1. After the installation its completed, we are ready to start developing, 
for this, start by adding this folder to your preferred IDE
2. Create any element needed inside the ModX admin, and once you are finished,
open a terminal and run:  
`docker exec -ti modxbaseenviroment_web_1 sh -c "cd /var/www/html && Gitify extract"`
3. You'll see a new `_data` folder inside the html folder, there you can find
all the plain files extracted from ModX for you to work directly with your preferred IDE
4. When you are done with the changes on the files, run the command:  
`docker exec -ti modxbaseenviroment_web_1 sh -c "cd /var/www/html && Gitify build && rm -fr /var/www/html/core/cache"`  
This will have your changes commited into ModX.  
Depending on the IDE you are using, you can add this command as an action
when you press the save button, for example for VSCode, you can follow 
[this tutorial](https://medium.com/better-programming/automatically-execute-bash-commands-on-save-in-vs-code-7a3100449f63)
to have the command called everytime you save a file in your IDE.
5. Make sure to add the `_data` folder to git and commit those to the repo.
6. Follow the standard GIT workflow defined on the best practices manual.
