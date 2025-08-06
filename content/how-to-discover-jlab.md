# How to discover JupyterLab APIs

(sec:learn-example)=

## Learning from example

### Setting the scene

- I only want my command to appear in notebooks
- I know that this already holds true for built-in commands
- We can hypothesise that the disable-command feature is also what hides it from the combo box with {kbd}`Ctrl` + {kbd}`Shift` + {kbd}`C`
- Let's pick a command and look at it, e.g. `run selected`.

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

- I'm expecting to see an extension that uses the `addCommand` feature that we are using to add commands.
- I come across something in `packages/mainmenu-extension/schema/`, let's click that link — I'm expecting something main-menu-like: https://github.com/jupyterlab/jupyterlab/blob/7bca584707aee4ec29cba40a814bdd787f566219/packages/mainmenu-extension/schema/plugin.json#L105
- I navigate to the root of this `mainmenu-extension` package, because I'm expecting to see this implemented in TypeScript, not JSON.
- I see `src/index.ts`, and open it up
- I search for "run selected" in this file
- I find some function `addSemanticCommand` that defines a `Run Selected` function: https://github.com/jupyterlab/jupyterlab/blob/7bca584707aee4ec29cba40a814bdd787f566219/packages/mainmenu-extension/src/index.ts#L615-L628
- I click on `addSemanticCommand` to bring up GitHub's rich explorer
- On the RHS I see "addSemanticCommand" defined in `packages/application/src/utils.ts`
- This feels confusing, and a rabbit hole --- I don't see any specific "am I enabled" logic

## Step back

- I do see `codeRunners.run`. What happens if I search for that?
- I get a hit on `packages/notebook-extension`! that sounds promising: https://github.com/jupyterlab/jupyterlab/blob/7bca584707aee4ec29cba40a814bdd787f566219/packages/notebook-extension/src/index.ts#L3836
- I can see an `isEnabled` function.
- How do I use it? I don't have `semanticCommand`...
- Let's look at what `addSemanticCommand.add` does by clicking `add`' here: https://github.com/jupyterlab/jupyterlab/blob/7bca584707aee4ec29cba40a814bdd787f566219/packages/notebook-extension/src/index.ts#L3836
- This takes me to the implementation of add: https://github.com/jupyterlab/jupyterlab/blob/main/packages/apputils/src/semanticCommand.ts#L57
-
