# LeanIX Webhooks Subscription Upsert Action

This action provides a standard way of upsert (update or create) a subscription in the Webhooks for all regions.

## Usage

This action reads the subscription definition from a file and calls Webhooks endpoints to upsert the provided subscription.
(Here is an example [integration-api-workspace-created-events](subscriptions/integration-api-workspace-created-events.json) that shows the structure.
Use in advance the provided [leanix/secrets-action](https://github.com/leanix/secrets-action) to inject the required secrets.

A simple provision step in the would look like this:
```yaml
- name: Upsert subscriptions to webhooks
  uses: leanix/webhooks-subscription-upsert-action@main
  with:
    environment: 'prod'  
```
This reads the file `webhooks-subscription-definition.json` from the root of your repository and register it globally on all prod instances of Webhooks.

### Azure Function support
In case the subscription must define a `targetUrl` that points to an azure function, the azure function's url first needs to be resolve. This logic is also embedded inside the action and for that use case the `azure_function_app_name` and `azure_function_name` must be specified. The action will resolve the url and write it into the environment variable `$AZURE_FUNTION_URL`, which can be refered inside the subscription definition. (Here is an [example](subscriptions/integration-configuration-changed-events.json).)


### Input Parameter
| input | required | default | description |
|-------|----------|---------|-------------|
|subscription_source|no|`webhooks-subscription-definition.json`|The location for subscriptions. The default value is considered a file path, but if is a directory path, then all the files in that directory are processed by this action.|
|environment|yes|test|The environment to provision to, e.g. test or prod|
|region|no|-|The region to provision to, e.g. westeurope or australiaeast. Leave empty to provision to all regions.|
|azure_function_app_name|no|-|A Azure Function App name in case the subscription should connect an azure function, eg: `functions-westeurope-prod-sailors`
|azure_function_name|no|-|A Azure Function name inside the given app in case the subsprition should connect a azure function, eg: `IntegrationsSlackMsg`
 

## Requires
This action requires following GitHub actions in advance:
- [leanix/secrets-action@master](https://github.com/leanix/secrets-action)

## Copyright and license
Copyright 2021 LeanIX GmbH under the [Unlicense license](LICENSE).
