# Style guide and convention

This is a basic development style guide which help to write clean and uniform code.

Note: [Hound](https://github.com/houndci/hound) can help by automatically review your pull requests.

## Github

- Use a pull request to start working on a feature branch.
- Rebase on top of master.
  _Rebase your feature branch on top of master before merging. It's a good idea to rebase before asking for a review._
- Write a [good commit message](https://chris.beams.io/posts/git-commit/).
  _If necessary add a summary after it to give context._
- Squash or Fixup multiple commits in a single consistent message.
  _'Fix typo' does not add any information to the feature._
- Push your branch and ask for a review.
  _When asking for review try to give as more as info you can contextualize to allow other developers to read through your code_
- Delete your branch after merging

## Ruby

- https://github.com/bbatsov/ruby-style-guide
- RSpec: http://betterspecs.org/

## Rubocop

[Rubocop](https://github.com/rubocop-hq/rubocop) is a style checker completely configurable, see [.rubocop.yml](https://github.com/MaisonetteWorld/maisonette-backend/blob/master/.rubocop.yml). It reports and can also automatically fix code offences.

## Decorating classes

Solidus development relies heavily on decorators so we have special rules for
them. When we need to patch some code, we use [prependers](https://github.com/nebulab/prependers). In addition to
reading the gem's readme, these rules also apply:

- be contained in the `app/prependers/` folder where the decorated class belongs to (i.e. `app/prependers/models/` for
  models, `app/prependers/controllers/` for controllers,...);
- should be per-feature to prevent huge code dumpster classes;
- be contained in a folder structure named after the class you need to decorate with the class name suffixed with
  (i.e. `Spree::Price` will be decorated in `app/prependers/models/spree/price/my_awesome_feature.rb`,
  `Spree::CheckoutController` will be decorated in `app/prependers/controllers/spree/checkout_controller/a_brand_new_action.rb`);
- be wrapped in a namespace that follows the structure of the directory nesting (i.e.
  `app/prependers/mailers/spree/order_mailer/cool_email.rb` will be wrapped in the namespace
  `Spree::OrderMailer::CoolEmail`);
- prependers will be namespaced with the inline module format with the `::` notation (rubocop rules have beeen
  configured accordingly for the `app/prependers` folder).

### Examples on decorating classes

**EXAMPLE** - Adding an instance method to `Spree::Product`:

```ruby
# This is contained in app/prependers/models/spree/product/wuut.rb
module Spree::Product::Wuut
  def display_wuut
    "WUUT! #{super} is the coolest product ever!"
  end
end
```

---

**EXAMPLE** - Adding a class method and a scope to `Spree::Product`:

```ruby
# This is contained in app/prependers/models/spree/product/wuut.rb
module Spree::Product::Wuut
  def self.prepended(base)
    scope :wuut, -> { where(name: 'WUUT') }
    base.extend ClassMethods
  end

  module ClassMethods
    def display_wuut
      "WUUT! This website is awesome!"
    end
  end
end
```

---

**EXAMPLE** - Adding an action to `Spree::Api::CheckoutsController`:

```ruby
# This is contained in app/prependers/controllers/spree/api/checkouts_controller/wuut.rb
module Spree::Api::CheckoutsController::Wuut
  def wuut
    render plain: "WUUT!"
  end
end
```
