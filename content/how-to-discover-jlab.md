# How to discover JupyterLab APIs

(sec:learn-example)=

## Learning from example

### Setting the scene

The context for this document is that we have a [JupyterLab extension](https://github.com/agoose77/jupyterlab-stateless-run) which provides a new command (with shortcut). Right now, this command appears in all contexts, whereas we want to enable it only for notebooks.

To set about fixing this, how would one approach the JupyterLab code-base to figure out the proper code to write? We can start by listing our initial state:

:::{important} Initial assumptions and ideas

- I only want my command to appear in notebooks.
- I know that this already holds true for built-in commands like "Render all Markdown".
- We can hypothesise that the disable-command feature is also what hides it from the combo box (via {kbd}`Ctrl` + {kbd}`Shift` + {kbd}`C`).
- We can therefore investigate how command works, to learn about the proper API.
  :::

### Searching for example commands

I know that JupyterLab is hosted and developed on GitHub. This is helpful, because GitHub search is really powerful. You can use regular expressions, in particular, which is often a helpful way of searching for something specific across thousands of repositories (e.g. to answer the question "who is using this code").

```{code}
:label: code:srch

repo:jupyterlab/jupyterlab "render all markdown"
```

We can use GitHub Search to find the string `"render all markdown"` in the jupyterlab repo (see @code:srch). The `""` quotes are used to search for the entire string, rather than OR across terms. We already know that we're looking for a command, because that's how menu-items are implemented (from our previous discussion). However, we won't use the term `command` yet, because the search isn't _that_ good. See @fig:srch-code for a screenshot of my search results.

:::{figure} media/code-search.png
:label: fig:srch-code

GitHub Code search results for the search query given in @code:srch. There are hits in three files.

:::

There are three results. Nice! Sometimes you'll find a lot more hits, which just means the next step takes longer as one backtracks to try another result.

### Filtering search results

When searching through a code-base, it _can_ be useful to look at the test suite. However, oftentimes the test suite is actually not what we're looking for, and matches against test files are unwanted. One usually has a sense of whether test files will help or harm your discovery process. In this case, we're looking for _actual_ commands that are registered in JupyterLab, which _won't_ be defined by the test suite. So, we can opt to ignore files that are tests with the following query:

```{code}
:label: code:srch-no-tst

repo:jupyterlab/jupyterlab "render all markdown" -path:test
```

The query in @code:srch-no-tst excludes results that have `test` somewhere in the file path. That might be too permissive, but in our case it helps:
:::{figure} media/code-search-no-test.png
:label: fig:srch-code-no-test

GitHub Code search results for the search query given in @code:srch-no-tst. There are hits in a single file.

:::

This singular search result matches against a package called `notebook-extension`. The JupyterLab repository is a <wiki:monorepo> which is built together at the same time. This sounds promising!

:::{note} Everything is an extension!

JupyterLab is mostly built out of extensions that build upon a core package. Even core functionality like the Notebook viewer, or the file browser, is implemented using this mechanism. This makes it possible for third-party extensions to replace these components with their own, and/or extend the existing functionality.
:::

(sec:ref-ex)=

### Looking at our example

Now that we've found a file containing a known notebook-only extension, we can see whether it helps us to understand more about JupyterLab's conditional command rendering. We're already expecting to see the `addCommand` API method being used.
:::{aside}
We ourselves are already using the `addCommand` method to define the custom shortcut.
:::

Let's look at the file. We see an interesting member of this object callled `isEnabled` (see @code:nb-cmd):

```{code} typescript
:filename: jupyterlab/packages/notebook-extension/src/index.ts
:lineno-start: 2436
:emphasize-lines: 2445
:label: code:nb-cmd
  commands.addCommand(CommandIDs.renderAllMarkdown, {
    label: trans.__('Render All Markdown Cells'),
    execute: args => {
      const current = getCurrent(tracker, shell, args);
      if (current) {
        const { content } = current;
        return NotebookActions.renderAllMarkdown(content);
      }
    },
    isEnabled
  });
```

This is probably the name of the function we'll need to define to determine whether the command is active. See @sec:learn-by-docs for an alternative approach that we can also use to figure out how to use this function.

(sec:learn-by-docs)=

## Learn by API docs

### Walking through the reference

One of the easiest ways to find useful APIs is to search through existing code to find usages. If you're into LLMs (and agree with their use), this is something that LLMs are quite good at. Once you've found usages, though, it can be helpful to pivot into using the API documentation that gives a technical picture of how to use the various application APIs. JupyterLab has its own [API reference](https://jupyterlab.readthedocs.io/en/latest/api/modules.html). First, let's figure out who owns the `addCommand` method. The `commands` variable in @code:nb-cmd is defined above (see @code:nb-cmds):

```{code} typescript
:filename: jupyterlab/packages/notebook-extension/src/index.ts
:lineno-start: 2201
:emphasize-lines: 2213
:label: code:nb-cmds
/**
 * Add the notebook commands to the application's command registry.
 */
function addCommands(
  app: JupyterFrontEnd,
  tracker: NotebookTracker,
  translator: ITranslator,
  sessionDialogs: ISessionContextDialogs,
  settings: ISettingRegistry.ISettings | null,
  isEnabled: () => boolean
): void {
  const trans = translator.load('jupyterlab');
  const { commands, shell } = app;
```

We can see from the destructuring assignment that it belongs to the `JupyterFrontEnd` class instance `app`. Let's look _that_ class up in the API reference using the search (see @fig:srch-jlab-frontend):
:::{figure} media/jupyterlab-api-frontend.png
:label: fig:srch-jlab-frontend

Screenshot showing search listings for the `JupyterFrontEnd` search term on the JupyterLab API documentation.
:::

We have two hits for the singular name `JupyterFrontEnd`. In the left hand side we can see single-character icons `N`, `C`, and `T` for a subsequent listing. These stand for the following:

`N`
: Namespace, a [TypeScript mechanism](https://www.typescriptlang.org/docs/handbook/namespaces.html) for gathering implementations.

`C`
: A TypeScript [class definition](https://www.typescriptlang.org/docs/handbook/2/classes.html).

`T`
: A TypeScript [type alias](https://www.typescriptlang.org/docs/handbook/namespaces.html).

We're looking for a _class_ definition, so we'll click the second result. On [that page](https://jupyterlab.readthedocs.io/en/latest/api/classes/application.JupyterFrontEnd-1.html), let's try and find a property called `commands` (see @fig:jlab-api-props):
:::{figure} media/jupyterlab-api-frontend-prop.png
:label: fig:jlab-api-props

Screenshot showing the properties of the `JupyterFrontEnd` class.
:::

We can't see anything called `commands`. Perhaps this property is defined by a superclass? Let's checkout the heirarchy (see @fig:jlab-api-heirarchy).
:::{figure} media/jupyterlab-api-frontend-hierarchy.png
:label: fig:jlab-api-heirarchy

Screenshot showing the hierarchy of the `JupyterFrontEnd` class.
:::
There is a [superclass called `Application`](https://lumino.readthedocs.io/en/latest/api/classes/application.Application-1.html). Let's look at _that_ class' properties (see @fig:jlab-api-app-props):
:::{figure} media/jupyterlab-api-application-prop.png
:label: fig:jlab-api-app-props

Screenshot showing the properties of the `Application` class.
:::
Clicking on the [`commands` member](https://lumino.readthedocs.io/en/latest/api/classes/application.Application-1.html#commands), we learn that it's a `CommandRegistry` type (see @fig:jlab-api-app-commands).
:::{figure} media/jupyterlab-api-application-commands.png
:label: fig:jlab-api-app-commands

Screenshot showing the `commands` property of the `Application` class.
:::

Now we can look at the [type definition](https://lumino.readthedocs.io/en/latest/api/classes/commands.CommandRegistry-1.html) of the `CommandRegistry` class, visible in @fig:jlab-api-app-commands (see @fig:jlab-api-commands):
:::{figure} media/jupyterlab-api-commands.png
:label: fig:jlab-api-commands

Screenshot showing the `CommandRegistry` class. Notice that the name of the documentation resource has changed in the top left from `@jupyterlab` to `@lumino`. This is because Lumino is a widget framework, built for and used by JupyterLab!
:::
This class defines the `addCommand` method that we are already familiar with. Let's now look at the [signature of this method](https://lumino.readthedocs.io/en/latest/api/classes/commands.CommandRegistry-1.html#addCommand), by clicking on it (see @fig:jlab-api-add-command):

:::{figure} media/jupyterlab-api-add-command.png
:label: fig:jlab-api-add-command

Screenshot showing the `addCommand` method of the `CommandRegistry` class.
:::

We can see that _this_ method takes some options, called `options`, of type `ICommandOptions`. Let's navigate [there](https://lumino.readthedocs.io/en/latest/api/interfaces/commands.CommandRegistry.ICommandOptions.html) (see @fig:jlab-api-command-options)!
:::{figure} media/jupyterlab-api-command-options.png
:label: fig:jlab-api-command-options

Screenshot showing the `CommandOptions` interface.
:::

Here, finally, we see the `isEnabled` [method](https://lumino.readthedocs.io/en/latest/api/interfaces/commands.CommandRegistry.ICommandOptions.html#isEnabled) that we were looking for! From the `properties` section of this API reference page, we can observe that the `isEnabled` member is _optional_, but if it is defined must confirm to some type `CommandFunc<boolean>`. Let's click on [`CommandFunc`](https://lumino.readthedocs.io/en/latest/api/types/commands.CommandRegistry.CommandFunc.html), and figure out what _that_ generic type actually resolves to (see @fig:jlab-api-command-func):
:::{figure} media/jupyterlab-api-command-func.png
:label: fig:jlab-api-command-func

Screenshot showing the `CommandFunc<T>` generic type.
:::

### Summarising our findings

OK, so we've found that a command _may_ define an `isEnabled` member. If it is defined, we should give it the type `() -> boolean`, which is TypeScript for a function that returns a boolean. What should this function test? See @sec:test-fn!

(sec:test-fn)=

## The business (logic) of enablement

Returning to our reference example in @sec:ref-ex, the `isEnabled` function was actually passed in as a function argument to `addCommands` (see @code:nb-cmds). We can go hunting for invocations of `addCommands` in the same module, and end up at [L1776](https://github.com/jupyterlab/jupyterlab/blob/31d45658d408fc4170ef91cce67c9c89645b1038/packages/notebook-extension/src/index.ts#L1776). That invocation uses a local variable `isEnabled`, defined [much higher in the file](https://github.com/jupyterlab/jupyterlab/blob/31d45658d408fc4170ef91cce67c9c89645b1038/packages/notebook-extension/src/index.ts#L593-L595). You can discover this by reading through the source code, or using GitHub's helpful inspector which lets you click on variable definitions, which pops up with a symbol menu (see @fig:gh-symbols):
:::{figure} media/github-symbols.png
:label: fig:gh-symbols

Screenshot showing All Symbols view in GitHub.
:::

Clicking the `isEnabled` _definition_ on L593 jumps [much higher in the file](https://github.com/jupyterlab/jupyterlab/blob/31d45658d408fc4170ef91cce67c9c89645b1038/packages/notebook-extension/src/index.ts#L593-L595), as expected!

You'll spot that this function is thin: it calls another function `Private.isEnabled(shell, tracker)`. `Private` is a JupyterLab-specific convention: JupyterLab uses `Private` namespaces to define implementation that should not be used by other code. So, we already know that we shouldn't be using the code here, but we _can_ look at how it is defined for inspiration!

Let's search within this file for `namespace Private`, which yields [the namespace definition](https://github.com/jupyterlab/jupyterlab/blob/31d45658d408fc4170ef91cce67c9c89645b1038/packages/notebook-extension/src/index.ts#L3852).

We can then find `isEnabled` [nested within](https://github.com/jupyterlab/jupyterlab/blob/31d45658d408fc4170ef91cce67c9c89645b1038/packages/notebook-extension/src/index.ts#L3883-L3891). It's very simple (see @code:priv-is-enabled):

```{code} typescript
:filename: jupyterlab/packages/notebook-extension/src/index.ts
:lineno-start: 3880
:label: code:priv-is-enabled

  /**
   * Whether there is an active notebook.
   */
  export function isEnabled(
    shell: JupyterFrontEnd.IShell,
    tracker: INotebookTracker
  ): boolean {
    return (
      tracker.currentWidget !== null &&
      tracker.currentWidget === shell.currentWidget
    );
  }

```

The code in @code:priv-is-enabled is simply testing whether the current shell widget is the current tracker widget. This raises two questions ... what is a `shell` and what is a `tracker`? Let's search the API docs for `shell` (see @fig:jlab-api-srch-shell) by first navigating to the _JupyterLab_ API docs, away from Lumino:

:::{figure} media/jupyterlab-api-srch-shell.png
:label: fig:jlab-api-srch-shell

Screenshot showing the search results for `shell` in the JupyterLab API docs.
:::

We can see many entries. Let's choose the least nested, most important sounding one, i.e. [the `application.LabShell` class](https://jupyterlab.readthedocs.io/en/latest/api/classes/application.LabShell.html). The resulting page states that `shell` is

> The application shell for JupyterLab.
>
> -- [JupyterLab API docs](https://jupyterlab.readthedocs.io/en/latest/api/classes/application.LabShell.html)

Not that useful a definition ... but we know it's an "application shell"! What about the `tracker`?
:::{figure} media/jupyterlab-api-tracker.png
:label: fig:jlab-api-tracker

Screenshot showing the search results for `tracker` in the JupyterLab API docs.
:::

We can search for `tracker` using the same logic. We see a [notebook result](https://jupyterlab.readthedocs.io/en/latest/api/interfaces/notebook.NotebookTools.IOptions.html#tracker) that has a `tracker` property. There, we can see an `INotebookTracker` interface type. Let's navigate [there](https://jupyterlab.readthedocs.io/en/latest/api/interfaces/notebook.INotebookTracker.html) to learn about it. It says that the notebook `tracker` is

> An object that tracks notebook widgets.
>
> -- [JupyterLab API docs](https://jupyterlab.readthedocs.io/en/latest/api/interfaces/notebook.INotebookTracker.html)

I think you can imagine what this means — there's an object whose responsibility is keeping track of notebook widgets. I.e. @code:priv-is-enabled is checking whether the current notebook widget is the current application widget! It stands to reason that we can simply copy this.

Fin.
