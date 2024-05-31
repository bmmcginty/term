# term

A library for easily writing text user interfaces.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  term:
    github: bmmcginty/term
```

## Usage

```crystal
require "./src/term"
w=MainWindow.new
tc=EditControl.new text: "00:00:00", height: 1
w.add tc
w.run
while 1
tc.text=Time.local.to_s("%H:%M:%S")
w.refresh
sleep 1
end
```

## Testing

Specs will be added, and results will be validated by way of full screen dumps.

## Development

add controls to src/controls/control_name.cr.
Writing code for controls is the most time consuming task at this point.
Each control should:
- provide focusable? to determine if a user can interact with it directly
- provide key(k) to accept keys
- provide a string via the text method to be used when rendering the control
- set user_x and/or user_y as appropriate when the user moves around the control
- set dirty to true when content or cursor position changes
Controls should not use boarders.
If you wish to add boarders or anything that isn't purely text,
those elements should be toggleable,
and set to disabled by default.

## Contributing

1. Fork it ( https://github.com/bmmcginty/term/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [bmmcginty](https://github.com/bmmcginty) Brandon McGinty - creator, maintainer
