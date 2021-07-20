# LeanIX Webhooks Subscription Upsert Action

This action provides a standard way of upsert (update or create) a subscription in the Webhooks for all regions.

## Usage

This action reads the subscription definition from a file and calls Webhooks endpoints to upsert the provided subscription.
Use in advance the provided [leanix/secrets-action](https://github.com/leanix/secrets-action) to inject the required secrets.

A simple provision step in the would look like this:
```yaml
- name: Upsert subscriptions to webhooks
  uses: leanix/webhooks-subscription-upsert-action@main
  with:
    environment: 'prod'  
```
This reads the file `webhooks-subscription-definition.json` from the root of your repository and register it globally on all prod instances of Webhooks.
### Input Parameter
| input | required | default | description |
|-------|----------|---------|-------------|
|subscription_file|no|`webhooks-subscription-definition.json`|The location of the file that contains the definition of the subscription that is used as the input for this action.|
|environment|yes|test|The environment to provision to, e.g. test or prod|
|region|no|-|The region to provision to, e.g. westeurope or australiaeast. Leave empty to provision to all regions.|
 

## Requires
This action requires following GitHub actions in advance:
- [leanix/secrets-action@master](https://github.com/leanix/secrets-action)

## Copyright and license
Copyright 2021 LeanIX GmbH under the [Unlicense license](LICENSE).
