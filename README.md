# Spree Avalara AvaTax official extension

[![CI](https://github.com/spree/spree_avatax_official/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/spree/spree_avatax_official/actions/workflows/ci.yml)

The new officially supported Avalara AvaTax extension for [Spree Commerce](https://spreecommerce.org/) using [Avalara REST API v2](https://developer.avalara.com/api-reference/avatax/rest/v2/).
* [Introduction](#introduction)
* [Maintenance & support](#maintenance--support)
* [Features](#features)
* [Installation](#installation)
* [Setup](#setup)
* [Migrating from spree_avatax_certified](#migrating-from-spree_avatax_certified)
* [Testing](#testing)
* [Contributing](#contributing)
* [About Spark Solutions](#about-spark-solutions)

## Introduction

<img src="https://spreecommerce.org/wp-content/uploads/2019/11/AvalaraCertifiedBadge_Refunds.png" width=150 align=right> <img src="https://spreecommerce.org/wp-content/uploads/2019/11/AvalaraCertifiedBadge_SalesTax.png" width=150 align=right> Avalara AvaTax is a cloud-based solution automating transaction tax calculations and the tax filing process. Avalara provides real-time tax calculation using tax content from more than 12,000 US taxing jurisdictions and over 200 countries, ensuring your transaction tax is calculated based on the most current tax rules.

The new officially certified Spree AvaTax extension helps Spree users and developers to switch from the old Avalara REST API V1 to the latest [Avalara REST API v2](https://developer.avalara.com/api-reference/avatax/rest/v2/). In the words of Avalara developers "the benefits are huge" as the new API V2 offers improved AvaTax performance, reliability and a wide range of new functionality.

And since AvaTax delivers sales and use tax calculations at the time of checkout or billing — in real time — the business benefits from implementing the new Spree AvaTax V2 extension are significant, potentially improving conversion rates and sales results.

## Maintenance & support

The new extension comes with technical support from both Spree Commerce core team and Avalara and will be maintained to keep up with the innovations introduced by Avalara in the future. The old extension will no longer be maintained or supported.

For more information, support and guidance on how to implement Spree AvaTax V2 extension feel free to:
* reach out through the [Spree contact form](https://spreecommerce.org/contact/)
* join the Spree slack channel #spree-avatax at [slack.spreecommerce.org](http://slack.spreecommerce.org)

## Features

1. Tax calculation (additional/included tax), US state tax, Canadian HST, VAT supported
2. Address validation for US & Canada
3. Commiting complete orders
4. Cancelling (voiding) orders
5. Refunding orders
6. GetByCodeService for getting SalesInvoice for order from Avatax
7. GetTaxService for getting totalTaxCalculated for order from Avatax
8. AvataxLog for logging API calls
9. Caching responses for improved performance
10. Multiple company (store) support

## Installation

1. Add this extension to your `Gemfile` with this line:
  ```ruby
  gem 'spree_avatax_official'
  ```

2. Install the gem using Bundler:

  ```bash
  bundle install
  ```

3. Run the install generator

  ```bash
  bundle exec rails g spree_avatax_official:install
  ```

4. Restart your server

  If your server was running, restart it so that it can find the assets properly.

## Setup

In order to configure tax calculation you need to:
1. [Connect Spree to AvaTax](#connect-spree-to-avatax)
2. [Configure Spree Stock Location](#configure-spree-stock-location)
3. [Configure AvaTax settings](#configure-avalara-avatax)
4. [Assign an AvaTax System Tax Code to a Tax Category](#assign-an-avatax-system-tax-code-to-a-tax-category)

### Connect Spree to AvaTax

In order to use `spree_avatax_official` extension, you need to configure your
Avatax credentials. To do so, open spree admin panel and go to **Configurations**
and then **Avatax Settings**.

<img width="1053" alt="Zrzut ekranu 2019-10-15 o 12 46 14" src="https://user-images.githubusercontent.com/581569/66825661-fcd5d000-ef4a-11e9-84b1-993b1a5c1996.png">

Company code, account number and license key can be
configured in the **Avatax Credentials** section of the form.

<img width="1053" alt="Zrzut ekranu 2019-10-16 o 12 20 14" src="https://user-images.githubusercontent.com/581569/66910959-da59ba80-f00f-11e9-8b96-ad2fa45b01ae.png">

* **Account Number:** Provided during your AvaTax account activation process.
* **License Key:** Provided during your AvaTax account activation process.
* **Company Code:** Company profile identifier in the AvaTax Admin Console.

**Service URL** is an URL to connect to the Development or Production AvaTax services. It can be configured in the **Avatax Endpoint urls** section below.

<img width="1053" alt="Zrzut ekranu 2019-10-16 o 12 24 35" src="https://user-images.githubusercontent.com/581569/66911009-fa897980-f00f-11e9-8524-1c64540a9a0f.png">

You can test settings you provided using the **Ping Avatax** button under the form

<img width="1053" alt="Zrzut ekranu 2019-10-16 o 12 25 26" src="https://user-images.githubusercontent.com/581569/66911077-17be4800-f010-11e9-89e0-e1982dd84e25.png">

### Configure Spree Stock Locations

In order for extension to be able to calculate the taxes, you need to set your stock locations addresses properly.
To do so, in Spree admin panel, go to `Configurations -> Stock Locations` and edit addresses of all Stock Locations  visible on the list.

### Configure Avalara AvaTax

Once connected, you configure additional settings.

<img width="1053" alt="Zrzut ekranu 2019-10-16 o 12 26 54" src="https://user-images.githubusercontent.com/581569/66911217-5c49e380-f010-11e9-86e7-f6fee2f0795d.png">

* **Enable Commiting Transactions:** Enables tax document submission to **Avalara’s AvaTax** service for record keeping. With this setting enabled, transactions will be posted and committed to the **AvaTax Admin Console**.
* **Enable Address Validation:** Option to enable or disable address validation

### Assign an AvaTax System Tax Code to a Tax Category

In order to assign **AvaTax System Tax Code** to **Spree Tax Category**, you need to open **Tax Categories** settings screen (`Configurations -> Tax Categories`), pick up existing or create a new **Tax Category** and fill the **Tax Code** input with the applicable **AvaTax System Tax Code**.

<img width="1053" alt="Zrzut ekranu 2019-10-15 o 12 51 04" src="https://user-images.githubusercontent.com/581569/66825678-095a2880-ef4b-11e9-840c-0a86dbc721b4.png">

If left blank, the **Tax Code** will
default to `P0000000`.

To see a listing of all available **AvaTax System** tax codes, see http://taxcode.avatax.avalara.com

## Migrating from spree_avatax_certified

The old extension spree_avatax_certified using the old Avalara REST API V1 will no longer be maintained or supported by the Spree team.

If you need to migrate from the old spree_avatax_certified to the new spree_avatax_official, in order to take advantage of the improved AvaTax performance, reliability and new functionality, there are various ways of ensuring backwards compatibility of Orders (eg. for refund purposes) which were committed to Avatax using the old extension.

Please reach out through the [Spree contact form](https://spreecommerce.org/contact/) to discuss an optimal strategy for your use case.

## Testing

First bundle your dependencies, then run `rake`. `rake` will default to building the dummy app if it does not exist, then it will run specs. The dummy app can be regenerated by using `rake test_app`.

```shell
bundle
bundle exec rake
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_avatax_official/factories'
```

## Contributing

If you'd like to contribute, please take a look at the
[instructions](CONTRIBUTING.md) for installing dependencies and crafting a good
pull request.

## License

Spree Avatax Official is copyright © 2019 [Spark Solutions Sp. z o.o.][spark].
It is free software, and may be redistributed under the terms specified in the
[LICENCE](LICENSE) file.

[LICENSE]: https://github.com/spree-contrib/spree_avatax_official/blob/master/LICENSE

## About Spark Solutions

[![Spark Solutions](http://sparksolutions.co/wp-content/uploads/2015/01/logo-ss-tr-221x100.png)][spark]

Spree Avatax Official is maintained by [Spark Solutions Sp. z o.o.](http://sparksolutions.co?utm_source=github) and
supported by [Avalara Inc.](https://www.avalara.com/us/en/index.html). The names and logos are trademarks of Avalara Inc.

We are passionate about open source software and [available for hire][spark].

[spark]:http://sparksolutions.co?utm_source=github
