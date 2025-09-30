# Markdown and Formatting Documentation

In case you've never used markdown, this one's for you <3

## Resources
- [Markdown Getting Started Guide](https://www.markdownguide.org/getting-started/)  
    - [Markdown Cheat sheet](https://www.markdownguide.org/cheat-sheet/ "Simple Reminders")
    - [Basic Syntax](https://www.markdownguide.org/basic-syntax/ "More in depth usage")


# Table of Contents
- [Headings](#headings)
- [Links](#links)
- [Images](#images)
- [Code blocks](#code-blocks)
- [Lists](#lists)
- [Blockquotes](#blockquotes)
- [Comments](#comments-non-rendering-notes)
- [Horizontal rules](#horizontal-rules)
- [Line breaks](#line-breaks)
- [Tables](#tables)
- [Collapsible Text](#collapsible-text)
- [Colored Text](#coloured-text)
- [Emojis](#emojis)

## Headings

Use `#` for headers. The number of `#` symbols corresponds to the heading level:

```markdown
# H1
## H2
### H3
#### H4
```

---

## Links

Use square brackets for the text and parentheses for the URL:

```markdown
[Example External Link](https://example.com)
```

- **Internal Link (MkDocs-style):**

```markdown
[Internal Page](/docs/Templates/mkdocs-formatting.md)
```

- You can also link to **sepcific sections**

```markdown
[Section in page](#section-name-all-lowercase)
```

Relative links are better for internal navigation. (In VS Code you can autofill relative paths).  
You can set that up [here](</docs/SOC Analysts/Workflow/Local Documentation Setup.md>)

---

## Images

Images are formatted similarly to links, with an exclamation mark (`!`) at the beginning.

### Upload Location

Place all images in the [`/docs/Images`](https://gitlab.infosec.ufl.edu/documentation/detection-playbook/-/tree/main/docs/Images) directory of the repository.

### Embedding Images

There are two main ways to include images:

1. **Direct Link to Image**  
   Markdown:
   ```markdown
   [View Image](/docs/Images/Test_Image.png)
   ```

2. **Embed Inline Image**  
   Markdown:
   ```markdown
   ![Test Image](/docs/Images/Test_Image.png)
   ```

   Example:  
   ![Test Image](/docs/Images/Test_Image.png)

Make sure image paths are correct relative to the root of the `docs` folder. (In VS Code you can autofill relative paths).

---

## Code Blocks

Use backticks for code formatting:

- **Inline Code:**  
  Use single backticks:
  ```markdown
  `inline code`
  ```

- **Multiline Code Blocks:**  
  Use triple backticks (specify language for syntax highlighting):
  ```python
  def hello():
      print("Hello, world!")
  ```

---

## Lists

### Unordered List

```markdown
- Item 1
- Item 2
  - Subitem
```

### Ordered List

```markdown
1. First item
2. Second item
```

---

## Blockquotes

Use `>` for quotes or notes:

```markdown
> This is a blockquote.
```

---

## Comments (Non-rendering Notes)

Markdown supports comment-style notes using this syntax:

```markdown
[comment]: # (This is a comment and will not render)
[comment]: <> (Also a valid comment)
```

Must be on a new line and **preceded by a line break** to avoid rendering issues.

Example:

[comment]: # (This comment is for internal use and will not appear in output)

---

## Horizontal Rules

To create a horizontal rule (divider):

```markdown
---
```

---

## Line Breaks

To create a line break (soft return), end the line with **two spaces**.  
For forced breaks, use `<br>` or `<br></br>`:

```markdown
Line one.<br>
Line two.
```

---

## Tables

Tables can be defined using pipes `|` and hyphens `-`:

```markdown
| Column 1 | Column 2 |
|----------|----------|
| Value 1  | Value 2  |
```

Rendered output:
| Column 1 | Column 2 |
|----------|----------|
| Value 1  | Value 2  |



# HTML and Formatting Documentation

Some handy features included in HTML are absent in Markdown.  
Fortunately, modern markdown parsers work with HTML, so we can leverage the powerful formatting features it provides.

Link to [W3 Schools HTML Guide](https://www.w3schools.com/html/default.asp)

## Collapsible Text 
To create collapsible text, use the following HTML:

```
<details>
  <summary>Click here to see more information</summary>
  This is the collapsible content.  You can include
  paragraphs, lists, code blocks, etc. within this section.
</details>
```

<details>
  <summary>Click here to see more information</summary>
  This is the collapsible content.  You can include paragraphs, lists, code blocks, etc. within this section.<br><br>
  Codeblock Example:
  <pre><code>You can include your example code here </code></pre>
</details>


## Coloured Text

``` HTML
<span style="color:cyan">some *cyan* text</span>
<span style="color:red">some *red* text</span>
<span style="color:lightgreen">some *lightgreen* text</span>
```

<br>

<span style="color:cyan">some *cyan* text</span>.  
<span style="color:red">some *red* text</span>.  
<span style="color:lightgreen">some *lightgreen* text</span>.

## Emojis

Any of [these emojis](https://gist.github.com/rxaviers/7360908) will be rendered in GitHub (but not VSCode)