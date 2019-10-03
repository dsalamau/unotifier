# UNotifier

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'unotifier'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install unotifier

## Usage

To store your notifications in database UNotifier uses provided ActiveRecord model. It must have the next attributes:
* `id` - required
* `key` - required
* `target` - required
* `title` - required
* `body` - optional
* `autohide_delay` - optional
* `link` - optional

`target` is a user or any other notification reciever entity. It also must provide several attributes:
* `login`
* `online?` - to determine whether to send *onsite* or *external* notification
* `locale` - to send proper locale to I18n


## Contributing

Bug reports and pull requests are welcome on GitLab at https://gitlab.com/hodlhodl-public/unotifier.
