Heroku RGeo Buildpack
=====================

Heroku RGeo [Buildpack](http://devcenter.heroku.com/articles/buildpacks) is a fork of Heroku's official Ruby buildpack with added binaries to support the rgeo gem.

*Note: Work in progress*

Usage
-----


Note: for basic process, See [heroku-buildpack-ruby README](https://github.com/heroku/heroku-buildpack-ruby/blob/83b14d1b95c1a4973fecc21b47945d2e05998f3f/README.md). The steps below assume a working knowledge of Heroku deployment.

### Creating a new app with rgeo support

```sh
$ heroku create --stack cedar --buildpack http://github.com/jcamenisch/heroku-buildpack-rgeo.git

$ git push heroku master
```

### Configuring an existing app with rgeo support

```sh
$ heroku config:add BUILDPACK_URL=http://github.com/jcamenisch/heroku-buildpack-rgeo.git LD_LIBRARY_PATH=/app/bin/geos/lib:/app/bin/proj/lib RECOMPILE_ALL_GEMS=1
...
$ heroku labs:enable user-env-compile
...
$ git push heroku master
...
```

The `RECOMPILE_ALL_GEMS` variable signals the build process to recompile the rgeo gem, so that the GEOS and PROJ binaries get linked in. The `user-env-compile` feature is necessary to allow `RECOMPILE_ALL_GEMS` to be read.

Both of these settings are unnecessary for the long term, and can be removed after RGeo is running properly, as follows.

```sh
$ heroku config:remove RECOMPILE_ALL_GEMS
...
$ heroku labs:disable user-env-compile
...
```

Known Issues
------------

Sometimes deployments fail with a message like the following:

```
...
-----> Fetching custom git buildpack... failed

 !     Heroku push rejected due to an unrecognized error.
 !     We've been notified, see http://support.heroku.com if the problem persists.


To git@heroku.com:app-name.git
 ! [remote rejected] master -> master (pre-receive hook declined)
error: failed to push some refs to 'git@heroku.com:app-name.git'
...
```

This problem is intermittent, and the solution is to repeat the deployment.
