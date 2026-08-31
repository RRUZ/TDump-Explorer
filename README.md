<p align="center">
  <img src="https://github.com/RRUZ/TDump-Explorer/blob/main/images/banner.png?raw=true" alt="TDump-Explorer banner"/>
</p>

# TDump Explorer

**TDump Explorer** is a native Windows GUI for exploring the reports produced by Embarcadero's `TDUMP` and `TDUMP64` utilities. It turns textual dump output into a navigable, source-linked document model while retaining fast access to the original report.


<p align="center">
  <img src="https://github.com/RRUZ/TDump-Explorer/blob/main/images/1.png?raw=true" alt="TDump-Explorer preview 1"/>
</p>

<p align="center">
  <img src="https://github.com/RRUZ/TDump-Explorer/blob/main/images/2.png?raw=true" alt="TDump-Explorer preview 2"/>
</p>

<p align="center">
  <img src="https://github.com/RRUZ/TDump-Explorer/blob/main/images/3.png?raw=true" alt="TDump-Explorer preview 3"/>
</p>

<p align="center">
  <img src="https://github.com/RRUZ/TDump-Explorer/blob/main/images/4.png?raw=true" alt="TDump-Explorer preview 4"/>
</p>

<p align="center">
  <img src="https://github.com/RRUZ/TDump-Explorer/blob/main/images/5.png?raw=true" alt="TDump-Explorer preview 5"/>
</p>

Open a generated `.tdump` report directly, or open a supported binary and let the application run the most appropriate installed TDUMP tool. 



## Highlights

- **Open reports or binaries.** Drag and drop files, select one or more files from the Open dialog, or pass a file on the command line. Binary input is processed with `TDUMP`/`TDUMP64`; report input is parsed directly.
- **Format-aware navigation.** Structured views are available for PE, ELF, Mach-O, OMF, AR archives, and Borland debug information, with diagnostic/source-backed fallbacks for content that cannot be fully projected.
- **PE analysis.** Browse DOS and PE headers, data directories, sections, imports (including delayed imports), exports, resources, and relocation blocks.
- **Debug-information views.** Inspect Borland subsection directories, source modules and files, symbol data, global symbols, and global types. Very large Borland reports use a compact indexed representation.
- **Native-format projections.** Explore Mach-O architectures, load commands, sections, symbols, dynamic-symbol metadata, imports, and indirect symbols; or ELF headers, sections, program headers, symbols, dynamic entries, and relocations grouped by source section.
- **Virtual raw report view.** The original TDUMP report remains available through a virtualized, syntax-highlighted RAW view with debounced background filtering and optional synchronization to the selected structured node.
- **Large-report conscious.** Reports are memory-mapped, line-indexed, and decoded on demand. Model nodes retain source spans rather than copying report text, and table rows are generated lazily.
- **Practical workflow features.** Multiple files are queued and analyzed one at a time, each completed document opens in its own tab, and the activity log records tool parameters, exit status, diagnostics, and timing.

## Supported input

TDump Explorer recognizes pre-generated TDUMP reports (`.tdump` and compatible text reports) and the following binary extensions:

| Category | Extensions |
| --- | --- |
| Windows executables and packages | `.exe`, `.dll`, `.bpl`, `.dpl`, `.ocx`, `.cpl`, `.scr`, `.com`, `.sys` |
| Objects and libraries | `.obj`, `.o`, `.lib`, `.ar`, `.a` |
| ELF and Mach-O | `.elf`, `.so`, `.dylib`, `.bundle`, `.mach` |
| Delphi units | `.dcu` |

Actual coverage depends on the report emitted by the installed TDUMP utility. COFF and Delphi-unit input currently use diagnostics/fallback projections when TDUMP cannot emit a normal structured report.

## How it works

```text
binary file ──> TDUMP / TDUMP64 ──> temporary report ─┐
                                                      ├─> mapped text source ─> parser ─> document tab
.tdump report ────────────────────────────────────────┘
```

## Requirements

- An installed Embarcadero RAD Studio / Delphi installation that provides `tdump.exe` or `tdump64.exe` for binary analysis

