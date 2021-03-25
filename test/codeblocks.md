title: Code block tests
date: yesterday

Code block tests
================

![Image test](https://raw.githubusercontent.com/eddieantonio/i/master/imgcat.png)<br/>after a break

This is [a test link](https://brettterpstra.com). <span class="test span">This is a test of html tag sytling.</span>[^fn1]

| a table | to see | how |
| :---- |----|:---:|
coloring | works|out

    Indented code
    This should just display as indented text

Lorem ipsum [dolor sit amet][reflink], consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. [Excepteur sint occaecat](https://test.com) cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

[reflink]: https://brettterpstra.com/should/become/inline "This should become an inline link"

* list test
* more list with **some bold** in it
  * more list nested

---

1. Numbered list
2. it has numbers
3. neat

## Nested, malformed language

1. If you're using the `develop` branch then it is recommended to set up a proper development environment ("Setting up a dev environment" below) however one can install the develop versions of the dependencies instead:
   ``` bash
   1 scripts/fetch-develop.deps.sh
   ```
Whenever you git pull on `riot-web` you will also probably need to force an update
to these dependencies - the simplest way is to re-run the script, but you can also
manually update and rebuild them:

```bash bin
cd matrix-js-sdk
  git pull
yarn install # re-run to pull in any new dependencies
  cd ../matrix-react-sdk
     git pull
yarn install
```

Or just use https://riot.im/develop - the continuous integration release of the
develop branch. (Note that we don't reference the develop versions in git directly
due to https://github.com/npm/npm/issues/3055.)

1. super indented
       
       ```bash bin
       cd matrix-js-sdk
          - git pull
       ```

### Outdented, no language

Wait a few seconds for the initial build to finish; you should see something like:
```
Hash: b0af76309dd56d7275c8
Version: webpack 1.12.14
Time: 14533ms
         Asset     Size  Chunks             Chunk Names
     bundle.js   4.2 MB       0  [emitted]  main
    bundle.css  91.5 kB       0  [emitted]  main
 bundle.js.map  5.29 MB       0  [emitted]  main
bundle.css.map   116 kB       0  [emitted]  main
    + 1013 hidden modules
```
   Remember, the command will not terminate since it runs the web server
   and rebuilds source files when they change. This development server also
   disables caching, so do NOT use it in production.

## Indented, no language

Open http://127.0.0.1:8080/ in your browser to see your newly built Riot.

If you're building a custom branch, or want to use the develop branch, check out the appropriate
riot-web branch and then run:

    docker build -t vectorim/riot-web:develop \
       --build-arg USE_CUSTOM_SDKS=true \
       --build-arg REACT_SDK_REPO="https://github.com/matrix-org/matrix-react-sdk.git" \
       --build-arg REACT_SDK_BRANCH="develop" \
       --build-arg JS_SDK_REPO="https://github.com/matrix-org/matrix-js-sdk.git" \
       --build-arg JS_SDK_BRANCH="develop" \
       .


## Language via hashbang

```
#!/usr/bin/env ruby
def convert_markdown(input)
  @headers = get_headers(input)
  # yaml/MMD headers
  in_yaml = false
  if input.split("\n")[0] =~ /(?i-m)^---[ \t]*?(\n|$)/
    @log.info("Found YAML")
    # YAML
    in_yaml = true
    input.sub!(/(?i-m)^---[ \t]*\n([\s\S]*?)\n[\-.]{3}[ \t]*\n/) do |yaml|
      m = Regexp.last_match

      @log.info("Processing YAML Header")
      m[0].split(/\n/).map {|line|
        if line =~ /^[\-.]{3}\s*$/
          line = c([:d,:black,:on_black]) + "% " + c([:d,:black,:on_black]) + line
        else
          line.sub!(/^(.*?:)[ \t]+(\S)/, '\1 \2')
          line = c([:d,:black,:on_black]) + "% " + c([:d,:white]) + line
        end
        if @cols - line.uncolor.size > 0
          line += " "*(@cols-line.uncolor.size)
        end
      }.join("\n") + "#{xc}\n"
    end
  end
end
```

## Wrapping indented code

    ```
    Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
    Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    ```

[^fn1]: this should end up under its origin paragraph

## more headlines

## for testing

## index listing

## and indentation

## almost enough

## gotta get to 10

