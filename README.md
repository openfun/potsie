# Potsie

Potsie is a collection of [Grafana](https://grafana.com/grafana/) dashboards
for learning analytics.

## Getting started

Once you have cloned this project, bootstrapping it should be as easy as typing
the following command from your terminal:

```
$ make bootstrap
```

Now you are ready to fire up grafana using:

```
$ make run
```

After a few seconds, the application should be running at
[localhost:3000](http://localhost:3000). Default admin credentials are
`admin:pass`. Once logged in, running grafana instance should be provisioned
with all dashboards versioned in this repository.

## Developer guide

### Working on dashboards

Potsie dashboards are written using the [Jsonnet templating
language](https://jsonnet.org) with the help of the [grafonnet
library](https://github.com/grafana/grafonnet-lib). Sources are stored in the
`src/` directory and should be compiled to plain JSON before being sent to
grafana.

Sources compilation can be done using the _ad hoc_ command:

```
$ make compile
```

Once compiled, our `potsie` provisioner (see
[potsie.yaml](./etc/grafana/provisioning/dashboards/potsie.yaml)) should
automatically load new or modified dashboards in running grafana instance
(after at most 3 seconds). You should refresh your web browser to see
modifications.

> _nota bene_: you can see compiled sources in the `var/lib/grafana/` directory
> from this repository (look for JSON files).

To automatically compile sources upon saved modifications, we provide a watcher
that requires to install the
[inotify-tools](https://github.com/inotify-tools/inotify-tools/wiki) dependency
for your system. It can be run using:

```
$ make watch
```

### Quality checks

To respect Jsonnet standards, we recommend to use official language formatter
and linter:

```bash
# Format sources
$ make format

# Lint sources
$ make lint
```

You can also use the `bin/jsonnetfmt` or `bin/jsonnet-lint` helper scripts for
custom use of the related tools. Adding a Git pre-commit hook script to
autoformat sources before committing changes would be an example usage of those
scripts.

### Other helper scripts

To install new dependencies, you should use the `bin/jb` wrapper script we
provide. This script uses the [Jsonnet
Bundler](https://github.com/jsonnet-bundler/jsonnet-bundler), _aka_ `jb`
package manager to handle project requirements. To list available commands and
options, use the `--help` flag:

```
$ bin/jb --help
```

If you want to play with the Jsonnet compiler, we also provide a wrapper
script, see:

```
$ bin/jsonnet --help
```

## Contributing

This project is intended to be community-driven, so please, do not hesitate to
get in touch if you have any question related to our implementation or design
decisions.

We try to raise our code quality standards and expect contributors to follow
the recommandations from our
[handbook](https://openfun.gitbooks.io/handbook/content).

## License

This work is released under the MIT License (see [LICENSE](./LICENSE.md)).
