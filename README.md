# Reception

⚠️ **As this solution has not fullfilled our expectations, this version is discontinued. See [ninech/reception](https://github.com/ninech/reception) for a complete rewrite in go.** ⚠️

A dashboard and reverse proxy for your
[**docker-compose**](https://docs.docker.com/compose/) projects.
It's built around [docker-gen](https://github.com/jwilder/docker-gen),
[dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) and
[nginx](https://nginx.org/) reverse proxies.

![A screenshot of the application.](https://cloud.githubusercontent.com/assets/804532/22060077/b49f6a2a-dd6f-11e6-9466-88ec8ab4a480.png)

## About

This project uses docker-gen to query docker for any docker-compose projects that are running. For every container of those projects that exposes a port (i.e. there's an `ports:` line in your `docker-compose.yml`) it creates an entry on the overview page and a virtual host in nginx. We configure dnsmasq to make sure that '_anything_.docker' resolves to *localhost*. Therefore, you get nice links like *yourcontainer.docker* that resolves to your container. Even as you fire up and shut down new docker-compose projects, docker-gen will update the entry page and the vhost configuration.

## Installation

For resolving the `.docker` local top-level domain to `localhost`, changes to
your local configuration are required. We rely on *dnsmasq* for the resolution
of `.docker` to `localhost`. We installed it locally and did not yet explore a
Docker-based solution.

### Linux

**WARNING: The linux instructions are not yet thoroughly tested!**

On Linux, you only need dnsmasq locally and *should* be able to nginx and
docker-gen through `docker-compose up`.

So, install dnsmasq using your package manager:

    # Ubuntu, Debian, etc.
    sudo apt install dnsmasq
    # RedHat, CentOS, Fedora, etc.
    sudo yum install dnsmasq

Edit the dnsmasq configuration and add the following lines.
The file is probably in `/etc/dnsmasq.conf`.

    address=/docker/127.0.0.1
    address=/docker/::1

Next, make sure that *dnsmasq* is responsible for resolving the `.docker` TLD:

    sudo -s
    mkdir /etc/resolver/docker
    echo "nameserver ::1" > /etc/resolver/docker
    echo "nameserver 127.0.0.1" >> /etc/resolver/docker

Now you shall start *dnsmasq*:

    systemctl enable dnsmasq
    systemctl start dnsmasq

Clone this repository if you haven't done so already:

    git clone https://github.com/ninech/reception.git && cd reception

Finally fire up the Docker container:

    docker-compose up

Try to go to http://reception.docker.

### macOS

We assume you have *docker* and *docker-compose* installed somehow!

Install *reception* using [homebrew](https://brew.sh/):

    brew install ninech/reception/reception

Now, add the following two lines to `/usr/local/etc/dnsmasq.conf`:

    address=/docker/127.0.0.1
    address=/docker/::1

This makes all requests to *dnsmasq* resolve to `localhost`.
Next you need to register *dnsmasq* as the resolver for the `docker` TLD. Run the
following on your command-line

    sudo -s
    mkdir /etc/resolver/docker
    echo "nameserver ::1" > /etc/resolver/docker
    echo "nameserver 127.0.0.1" >> /etc/resolver/docker

At last, start the services:

    sudo brew services start nginx
    sudo brew services start dnsmasq
    sudo brew services start ninech/reception/reception

Now try to go to http://reception.docker.

## Caveats

### "Main" container

The "main" container must be called `app`:

    version: '2'
    services:
      app:    <----- like this
        image: nginx
        ports:
          - 80

### Ports

In your `docker-compose.yaml` file, you shall only expose the 'main' HTTP port,
because it's hard to reliably determine the HTTP port for the reverse proxy.
Also, you should not give a specific local port.
The reverse proxy will bind to the random port assigned by Docker
without any problems. This way you avoid port collisions across projects.

**Do**

    version: '2'
    services:
      app:
        image: nginx
        depends_on: pgsql
        ports:
          - 80    <----- like this
      pgsql:
        image: postgresql

**Don't**

    version: '2'
    services:
      app:
        image: nginx
        depends_on: pgsql
        volume:
          - ./php:/usr/share/nginx/html
        ports:
          - 80:80    <----- and _not_ like this
      pgsql:
        image: postgresql
        ports:
          - 5432:5432    <----- and _not_ like this

## Troubleshooting

### Log files for macOS

The logs are located under `/usr/local/var/log`:

```shell
tail -f /usr/local/var/log/docker-gen.log
tail -f /usr/local/var/log/nginx/*
```

### docker-compose projects can't start because of port conflicts

Most probably you assigned a fixed port mapping for any exposed ports. Look for something like the following:

```yml
version: 2
services:
  app:
    ports:
      -- "80:80"
```

In the case above, you would just replace `"80:80"` with `80`.

### Nginx does not update

If the overview page does not update and *\*.docker* links to new docker-compose projects do not work, then there might be a problem with any of your currently running *docker-compose* projects. (Most likely the problem's with the most recently started project!)

Check the following in any of your docker-compose projects:

* Do you only export the ports you need?
  * Remove any port you don't need to connect to!
* Does any container export more than one port?
  * Either make sure that one of the exposed ports is either 80, 8080 or 3000.
  * Or add an environment variable to that container called `VIRTUAL_PORT`. It's value must be the port number that is the http port for that container.

### Is dnsmasq running?

`dig +short foobar.docker @::1` should print `127.0.0.1`.

If it doesn't, it means that *dnsmasq* is not running.

### Is the DNS cache outdated?

_Note:_ dnsmasq should be up and running at this stage (see above).

`nslookup foobar.docker` should resolve to `127.0.0.1`.

If it doesn't, please flush the DNS cache:

```shell
# macOS
sudo killall -HUP mDNSResponder

# Linux
systemctl restart named

# or

systemctl restart nscd
```
