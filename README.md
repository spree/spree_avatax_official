<h1>Spree Avalara AvaTax official extension</h1>

<p><a href="https://github.com/spree/spree_avatax_official/actions/workflows/ci.yml"><img src="https://github.com/spree/spree_avatax_official/actions/workflows/ci.yml/badge.svg?branch=master" alt="CI"></a></p>

<p>The officially supported Avalara AvaTax extension for <a href="https://spreecommerce.org/">Spree Commerce</a> using <a href="https://developer.avalara.com/api-reference/avatax/rest/v2/">Avalara REST API v2</a>.</p>

<ul>
  <li><a href="#introduction">Introduction</a></li>
  <li><a href="#maintenance--support">Maintenance &amp; support</a></li>
  <li><a href="#features">Features</a></li>
  <li><a href="#installation">Installation</a></li>
  <li><a href="#setup">Setup</a></li>
  <li><a href="#contributing">Contributing</a></li>
</ul>

<h2>Introduction</h2>

<p><img src="https://spreecommerce.org/wp-content/uploads/2019/11/AvalaraCertifiedBadge_Refunds.png" width="150" align="right"> <img src="https://spreecommerce.org/wp-content/uploads/2019/11/AvalaraCertifiedBadge_SalesTax.png" width="150" align="right"> Avalara AvaTax is a cloud-based solution automating transaction tax calculations and the tax filing process. Avalara provides real-time tax calculation using tax content from more than 12,000 US taxing jurisdictions and over 200 countries, ensuring your transaction tax is calculated based on the most current tax rules.</p>

<h2>Maintenance &amp; support</h2>

<p>This extension is maintained by the Spree Commerce core team and Avalara, and will be kept up to date with future Avalara platform changes.</p>

<p>For more information, support and guidance on how to implement the Spree AvaTax extension feel free to:</p>
<ul>
  <li>Read the <a href="https://spreecommerce.org/docs/integrations/tax/avalara">Spree Avalara AvaTax user documentation</a></li>
  <li>Reach out through the <a href="https://spreecommerce.org/contact/">Spree contact form</a></li>
  <li>Join the Spree Discord at <a href="https://discord.spreecommerce.org/">discord.spreecommerce.org</a></li>
</ul>

<h2>Features</h2>

<ol>
  <li>Tax calculation (additional/included tax), US state tax, Canadian HST, VAT supported</li>
  <li>Tax calculation on both line items and shipping charges</li>
  <li>Tax codes support for products and shipping (assignable per tax category)</li>
  <li>Multi-stock location support — origin-based tax calculation per shipment across your fulfilment network</li>
  <li>Tax exemptions — Entity Use Codes, VAT Business Identification Numbers, and Exemption Numbers</li>
  <li>Address validation for US &amp; Canada</li>
  <li>Committing complete orders as sales invoice transactions</li>
  <li>Cancelling (voiding) orders</li>
  <li>Refunding orders (full and partial)</li>
  <li>Client-side logging</li>
</ol>

<h2>Installation</h2>

<pre><code>bundle add spree_avatax_official &amp;&amp; bundle exec rails g spree_avatax_official:install</code></pre>

<p>Restart your server so that it can find the assets properly.</p>

<h2>Setup</h2>

<h3>Connect Spree to AvaTax</h3>

<p>Navigate to the <strong>Integrations</strong> tab in the Spree admin, locate the Avalara tile, and click <strong>Connect Avalara</strong> to open the setup form.</p>

<p>Enter the following credentials from your Avalara account:</p>
<ul>
  <li><strong>Account Number:</strong> Your unique Avalara account identifier.</li>
  <li><strong>License Key:</strong> The private key used to authenticate API requests.</li>
  <li><strong>Company Code:</strong> Company profile identifier in the Avalara account.</li>
  <li><strong>Environment:</strong> Select <strong>Sandbox</strong> for testing or <strong>Production</strong> for your live store.</li>
</ul>

<p>For full setup instructions including tax codes, tax exemptions, transactions, and address validation, see the <a href="https://spreecommerce.org/docs/integrations/tax/avalara">Spree Avalara AvaTax user documentation</a>.</p>

<h2>Contributing</h2>

<p>If you'd like to contribute, please take a look at the <a href="CONTRIBUTING.md">instructions</a> for installing dependencies and crafting a good pull request.</p>

<p>Copyright (c) 2026 <a href="https://sparksolutions.co">Spark Solutions Sp. z o.o.</a>, <a href="https://getvendo.com">Vendo Sp. z o.o.</a>, <a href="https://getvendo.com">Vendo Connect Inc.</a>, released under <a href="https://github.com/spree/spree_avatax_official/blob/master/LICENSE">MIT</a>.</p>
