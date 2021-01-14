# About this Repo

This repository holds the docker-compose configuration intended to run a 
modX development environment, from the basic infrastructure needed, to 
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
3. For local development you'll need to generate the ssl selfsigned 
   certificates, [here is a guide on how to do so](https://medium.com/the-new-control-plane/generating-self-signed-certificates-on-windows-7812a600c2d8)
   and place the `ssl.crt` and `ssl.key` files inside the certs folder.


## Using this image
Once you run the image, the current html and mysql folders are going to get 
populated with all the files for modx installation as well as mysql system files.

1. Configure environment variables: Inside the docker-compose.yml 
   file your can find the different values that can be configured for the images.  
   You need to look for the `MODX_SERVER_ROUTE` key, and update the ip address with
   the one corresponding to your computer's intranet ip.
   
2. Build the containers
```sh
docker-compose build
```

3. Run the containers
```sh
docker-compose run
```

4. The first time you'll run the container it'll take some time while it 
   downloads and installs the different components.


## Developing with this image

After the installation its completed, we are ready to start developing, 
for this, start creating your first components inside modx, and when you are
ready to test, run
