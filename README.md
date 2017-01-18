# Reception

A dashboard and reverse proxy for your
[**docker-compose**](https://docs.docker.com/compose/) projects.
It's built around [docker-gen](https://github.com/jwilder/docker-gen),
[dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) and
[nginx](https://nginx.org/) reverse proxies.

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

    address=/#/127.0.0.1
    address=/#/::1

**Warning:** If you already use *dnsmasq* for domain resolving, you must not add
the lines above, but those below:

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

Install *nginx*, *dnsmasq* and *docker-gen* using *[homebrew](http://brew.sh/)*:

    brew install nginx dnsmasq docker-gen

Now, configure add the following two lines to `/usr/local/etc/dnsmasq.conf`:

    address=/#/127.0.0.1
    address=/#/::1

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

Clone this repository if you haven't done so already:

    git clone https://github.com/ninech/reception.git && cd reception

In the current directory, start `docker-gen` (and leave it running!) like this

    sudo docker-gen -config docker-gen.osx.conf

You can also install a *LaunchDaemon*, but you need to edit the file first and
adjust the path to the `docker-gen.osx.conf` file!

    sudo cp ch.nine.reception.docker-gen.plist /Library/LaunchDaemons/
    sudo launchctl load -w /Library/LaunchDaemons/ch.nine.reception.docker-gen.plist

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
Also, you should not give a specific local port when you work on multiple
projects. The reverse proxy will bind to the random port assigned by Docker
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

### Investigate your setup

#### Is dnsmasq running?

`dig +short foobar.docker @::1` should print `127.0.0.1`.

If it doesn't, it means that *dnsmasq* is not running.

#### Is the DNS cache outdated?

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
