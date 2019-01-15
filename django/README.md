# Learning Django

This is a run through of the [Django Tutorial](https://docs.djangoproject.com/en/2.1/intro/tutorial01/) and building a simple light-weight, non-production web app with built-in web server.

## Environment
- Google Cloud with tcp:8000 enabled on firewall
- CentOS 7
- SQLite
- Port 8000 with no reverse proxy
- Foreground process - make a service later

## Startup

**Note**: Be sure to add your host name to "ALLOWED_HOSTS" inside of `settings.py`
1. Run the setup script as root
```
sudo ./setup.sh
```
2. Enable Python 3.5 from software collections
```
. /opt/rh/rh-python35/enable
```
3. Start it up! (note: address any errors that might occur such as migration to apply)
```
# Only allow this process the ability to bind to be accessible to 8000 for now.  Probably reverse proxy later
sudo firewall-cmd --add-port=8000/tcp
cd mysite
python manage.py runserver 0:8000
```

