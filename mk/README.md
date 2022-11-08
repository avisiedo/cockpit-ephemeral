# Makefile composition

The repository is using a way to compose the `Makefile` file which
empower the single responsability principal taken into the Makefile
file usage.

We have the following files:

```raw
Makefile                    # Minimal main Makefile
mk
├── README.md               # This documentation file
├── docker.mk
├── help.mk                 # Rule to print out generated help content from the Makefile's files
├── includes.mk             # Entry point included into the main Makefile
├── meta-general.mk
├── meta-docker.mk
├── printvars.mk            # print out variables
├── projectdir.mk           # Store at PROJECT_DIR the base directory for the repository
└── variables.mk            # Default values to the project variables that has not been
                            # overrided by the environment variables nor by configs/config.yaml
                            # file
```

## Usage

- Print out help: `make help`
- Prepare everything: `make prepare`
- Login to the ephemeral environment: `make ephemeral-login`
- Reserve a namespace: `make ephemeral-namespace-reserve`
- List the reserved namespaces: `make epehemeral-namespace-list`
- Deploy the application: `make ephemeral-deploy`
- Remove the application: `make ephemeral-undeploy`

> To login into your registries at mk/private.mk (see mk/private.example.mk)
> run `make .docker-login`

