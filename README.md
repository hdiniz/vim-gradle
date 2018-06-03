# vim-gradle

Create, compile and manage your Gradle projects without leaving vim!

## Installation

    Plug 'hdiniz/vim-gradle'

The plugin will use your project's Gradle wrapper or fallback to a Gradle installation.
Some commands (`:GradleInit [args]`, `:GradleWrapper [args]`) will require a Gradle installation.

## Usage

By default, you Gradle project will be loaded you open vim under a Gradle project. See |autoload|.
When the project is detected, the `:Gradle[!] <args>` command becomes available:

    :Gradle[!] compile

When executed with a `bang (!)`, the compilation is executed synchronously as if using `:make`. Otherwise the compilation is asynchronous and a output window is open.

Erros detected during built populate vim's quickfix window:

    :copen

## Commands

### _:Gradle[!] {args}_

When executed with the `bang (!)`, the compilation is synchronous and equivalent to running `:make {args}`.
Otherwise the build is started asynchronously and the output is redirected to an output window.

A default `errorformat` is provided so build errors can be listed on vim's quickfix.
_TODO: The default errorformat can be overriden or enhanced by vim-gradle extensions._

### _:GradleLoad_

Manually loads the Gradle project based on current buffer or current directory. Use when autoloading is disabled. See `g:vim_gradle_autoload`

### _:GradleInit {args}_

_*Requires Gradle installation_

Runs `gradle init {args}` on current directory.

### _:GradleWrapper {args}_

_*Requires Gradle installation_

Runs `gradle wrapper {args}` on current directory.

## Options

### _g:vim_gradle_autoload_
Default: 1

When a new buffer is open search 'build.gradle' and 'build.gradle.kts' files up on the directory tree.

If disabled, projects can be loaded via `:GradleLoad.`

### _g:vim_gradle_enable_rtp_
Default: 1

Allows vim-gradle to load additional gradle init script from vim-gradle extensions.

### _g:vim_gradle_bin_
Default: ''

Absolute path to the Gradle binary. Used for out-of-project commands and projects without a Gradle Wrapper.
Overrides |g:vim_gradle_home| and $GRADLE_HOME.

### _g:vim_gradle_home_
Default: ''

Absolute path to a Gradle installation. Used for out-of-project commands and projects without a Gradle Wrapper.
Overrides $GRADLE_HOME.

## Airline

TODO: support airline parts on project files and compilation window

## Extensions

Extensions can hook into Gradle init scripts by defining the function:

`[plugin]/autoload/gradle/extensions/{extension_name}.vim`

```vim
let s:gradle_folder_path = escape( expand( '<sfile>:p:h:h:h:h' ), '\' ) . '/gradle/'

function! gradle#extensions#{extension_name}#build_scripts()
    return [s:gradle_folder_path . 'extension_name.gradle']
endfunction
```

This can be used to define custom tasks and plugins on the project. The references scripts will load after the rootProject has been evaluated.

TODO: Allow extensions to provide a custom `errorformat`

## License

MIT


