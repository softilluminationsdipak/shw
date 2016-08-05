## SelectHomeWarranty
##### For all details, please refer the commit history, and source codes.
##### Most important and valuable sources for future work.

### Major component
Customer, Renewal, Claim, Account, Transaction, Contractor

#### Please refer the following URL for ERD of SHW
https://f.cloud.github.com/assets/3715794/1799707/0b0b0350-6baa-11e3-920a-c5243cf6455b.png

### Lead generation step
Customer can sign up for new contract via GAQ process(/quote).

Please check Site#quote, Site#purchase in controller.

GAQ step 1
  Site#quote
  
GAQ step 2
  Site#purchase (GET)
  
GAQ step 3
  Site#purchase (POST)

Payment can be processed after 7 days, with recurring billing mode.
And 2 payment options are available, just yearly and monthly option, based on customer's input.
  
### View template
Originally it used mootools, cip js library, and implemented major components with cip js, and ajax json.

So it takes so much time to load pages, and not flexible to update.

Heading to update mootools, cip by jquery, and bootstrap.

Being in temporary steps, mootools and jquery are using at the same time.

First loads mootools, which is followed by jquery library.

Backend template file:
  app/views/layouts/new_admin.html.erb

### System configuration
All configuration parameters are stored in config/installation.json,  config/installation_test.json.

### Save faxes in Google Cloud Storage account
When calling to retrieve faxes, it fetches all unread emails from email account.

And getting sender address, and fax content from attachment, and saves that in Google.

So SHW shows all faxes, stored in Google account.

Necessary account details can be found in config/google_storage.yml

Please keep it as safe.

And there is a background by sidekiq, to fetch faxes and save it automatically (app/workers/fax_fetch).

### Payment method
SHW uses Authorize.net as payment gateway.

And it uses 2 different merchant account, one for production, and one for staging.


