+++
title = 'Simple Cicd Setup'
date = 2024-10-29T08:43:09+01:00
draft = true
+++

Almost every software developer has built some kind of side project, which is great. But there are so many
projects that never leave local and are only visible through a GitHub repository. Because of this, here
is my simple ci-cd setup, which makes deploying applications easy. The goal of the setup is not high availability,
or to handle much load, but it should be a starting point for any small application. I have my setup running
on a raspberry pi, but it should work with any other linux server. It can deploy everything that runs in a docker container.

## Prerequisites
- SSH connection to server
- Ansible
- Docker

In case you don't have these setup, here is some help:
- ssh: https://www.digitalocean.com/community/tutorials/how-to-use-ssh-to-connect-to-a-remote-server
- ansible: https://docs.ansible.com/ansible/latest/getting_started/index.html
- docker: you can set up docker with this ansible role:
```yaml
- name: Update apt package index
  ansible.builtin.apt:
    update_cache: yes

- name: Install necessary packages for Docker
  ansible.builtin.apt:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - software-properties-common
    state: present

- name: Add Docker's official GPG key
  ansible.builtin.apt_key:
    url: https://download.docker.com/linux/raspbian/gpg
    state: present

- name: Set up the Docker repository
  ansible.builtin.apt_repository:
    repo: deb [arch=armhf] https://download.docker.com/linux/raspbian {{ ansible_distribution_release }} stable
    state: present

- name: Update apt package index again
  ansible.builtin.apt:
    update_cache: yes

- name: Install Docker
  ansible.builtin.apt:
    name: docker.io
    state: present

- name: Start Docker service
  ansible.builtin.service:
    name: docker
    state: started
    enabled: yes
```

## How the system works
The basic idea works as follows:
1. Deploy your application, either via ansible, portainer, or docker cli.
2. On commit, build a docker image and push it to your local docker registry. (this will be done automatically)
3. Watchtower, an application, will detect new image and restart app with new image
4. Done.

## Setting up CiCd Infrastructure
### Web Server(Caddy)
For some applications, I would recommend a web server such as caddy(e.g., portainer/docker registry).
Else you would need to expose single ports for all of these.
In an ansible role, you can configure caddy like this:
```yaml
- name: install rsync
  apt:
    name: rsync
    state: latest
- name: copy caddyfile
  copy:
    src: templates/Caddyfile
    dest: /etc/caddy/Caddyfile
- name: Deploy caddy
  community.docker.docker_container:
    name: caddy
    network_mode: host
    image: "caddy:2.7"
    volumes:
      - "/etc/caddy:/etc/caddy"
- name: restart caddy
  ansible.builtin.shell: docker restart caddy
```
Make sure to write your caddyfile into /roles/caddy/templates. You can learn more about caddyfiles [here](https://caddyserver.com/docs/caddyfile).
If you are having problems reaching your server via http, maybe check your firewall.
### Docker registry:
This is the registry, where we will push our dockerfile. Watchtower will be scaning this.
```yaml
- name: Deploy registry
  community.docker.docker_container:
    name: registry
    image: registry:2
    volumes:
      - /var/lib/registry:/var/lib/registry
    ports:
      - "127.0.0.1:5000:5000"
    restart_policy: always
```
We will also need to configure caddy to point to the registry. You should name your url how you want to.
```yaml
<url> {
	reverse_proxy 127.0.0.1:5000 <set this to the same port your registry is running on>
	basicauth /* {
			<user> <hashed-password>
	}	
}
```
You can also put all of these applications in a docker network, then you don't need to expose these ports. 
If you have caddy/ any other web server running, writing 127.0.0.1/localhost in front of the port will only make it accessible to your internal network, which caddy can forward the request to.
### Portainer
Portainer is a UI for Docker. You don't need to use it,
but I find it easier than always having to ssh into the server to check your deployments.
You can set it up with this ansible code:
```yaml
- name: run portainer
  community.docker.docker_container:
    name: portainer
    image: portainer/portainer-ce:alpine
    ports:
      - "127.0.0.1:9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/portainer:/data
    restart_policy: always
```
And we also need to add directive I caddy for it:
```yaml
<url> {
	reverse_proxy 127.0.0.1:9000
}
```
The first time you visit your portainer app, it will guide you through the setup.
### Watchtower
At last, we only need to deploy Watchtower, which checks if it can find new images in the registry, 
for all containers running and replaces them. With this ansible code (you can put it in a separate role or in the docker role) it will be up and running.
We don't need to expose the application in any other way.

## Deploying an application
If you want to deploy an app, you can either do it via ansible,
or poratiner ui/docker cli.
In my experience, while it is nice to also have your applications configured in code,
you need to be 100% certain that your image is already in the registry, else you ansible will fail. 
Once you created your container, all we need to do is create a new image on every commit and push it to the registry.
### Building and Pushing your Image on every commit.
For this, I am using GitHub actions, but you can use any other build system if you want.

The first step is to create the image, and then we need to push it.
For this, we can use this code in ./github/workflows/<name>.yaml

```yaml
name: Build and Push Docker Image for Raspberry Pi 4

on:
  push:
    branches:
      - main

  workflow_dispatch:

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Log in to Docker registry
        uses: docker/login-action@v2
        with:
          registry: ${{ secrets.DOCKER_URL }}
          username: ${{ secrets.DOCKER_NAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ secrets.DOCKER_URL }}/<image-name>
          file: ./Dockerfile
          platforms: linux/arm64, linux/arm/v7, linux/arm/v8
```

On every push to main, this action will first checkout your repo.

Then it will log in to your repository (make sure to set your GitHub action secrets: DOCKER_URL,DOCKER_PASSWORD,DOCKER_NAME as you configured in your caddyfile).

Then it will build and push your image to your registry.
If you are using a different server that a raspberry pi, you may need to change the platforms.

From there on watchtower will see the new image and update your docker container!


If you have any other questions or want to contribute to this post, feel free to open an issue/pr on this repo:

{{< github repo="sycrw/timkausemann.de" >}}

There you can also find the action doing it works, and a dockerfile for creating the image for this website.
