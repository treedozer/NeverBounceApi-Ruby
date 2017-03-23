NeverBounce API Ruby Wrapper
---

This is the fork of [official](https://github.com/NeverBounce/NeverBounceApi-Ruby) NeverBounce API Ruby wrapper. It provides helpful methods to quickly implement our API in your Ruby applications.

Installation
===

Add this line to your Rails application's Gemfile:
```
$ gem 'never_bounce', git: 'https://github.com/treedozer/never_bounce'
```
And then execute:
```
$ bundle install
```
Or install it yourself as:
```
$ git clone https://github.com/treedozer/never_bounce.git
$ cd never_bounce && gem build never_bounce.gemspec
$ sudo gem install never_bounce-0.1.5.gem
```

Usage
===

To start using the wrapper sign up for an account [here](https://app.neverbounce.com/register) and get your api keys [here](https://app.neverbounce.com/settings/api).

To initialize the wrapper use the following snippet, substituting in your `api username` and `api secret key`...

```
neverbounce = NeverBounce::API.new(API_USERNAME, API_SECRET_KEY)
```

You can now access the verify method from this class. To validate a single email use the following...

```
result = neverbounce.single.verify(EMAIL)
```

The `result` will contain a VerificationResult class instance. It provides several helper methods documented below...

```
result.get_result_code # Numeric result code; ex: 0, 1, 2, 3, 4
result.get_result_text_code # Textual result code; ex: valid, invalid, disposable, catchall, unknown
result.is(0) # Returns true if result is valid
result.is([0,3,4]) # Returns true if result is valid, catchall, or unknown
result.not(1) # Returns true if result is not invalid
result.not([1,2]) # Returns true if result is not invalid or disposable
```

Or validate multiple by sending public URL to csv file or URL encoded string of the contents of your emails list. Only for accounts with added default payment method
```
result = never_bounce.list.bulk(input: File.open('./emails.csv').read, input_location: 1)

result = neverbounce.list.status(result.job_id)
result.pending? # boolean
result.in_progress? # boolean
result.is_done? # boolean
result.is_failed? # boolean
result.get_status # description of job status

result = neverbounce.list.download(result.job_id, invalids: 1)
result = neverbounce.list.download_valid(result.job_id)
result = neverbounce.list.download(result.job_id)

result.valid # array with valid emails
result.invalid # array with invalid emails
result.bad_syntax # array with bad_syntax emails
result.catchall # array with catchall emails
result.disposable # array with disposable emails
result.unknown # array with unknown emails
result.all # array with all emails
```
