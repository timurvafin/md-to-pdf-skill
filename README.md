# md-to-pdf

Claude Code skill для конвертации Markdown в красивый PDF.

## Возможности

- 5 CSS-тем: professional, modern, academic, dark, minimal
- Автоопределение темы по контенту
- Поддержка кириллицы (PT Sans, PT Serif, Fira Code)
- Portrait и landscape ориентация
- Пайплайн: pandoc → HTML+CSS → Chrome headless → PDF

## Prerequisites

- [pandoc](https://pandoc.org/) — `brew install pandoc`
- Google Chrome или Chromium

## Установка

```bash
git clone https://github.com/timurvafin/md-to-pdf-skill.git ~/.claude/skills/md-to-pdf
```

## Использование

В Claude Code просто попросите:

- «сделай PDF из файла notes.md»
- «convert README.md to pdf»
- «экспорт в PDF с тёмной темой»

Или напрямую:

```bash
bash ~/.claude/skills/md-to-pdf/scripts/convert.sh -i input.md -o output.pdf -t modern
```

### Аргументы

| Флаг | Описание | По умолчанию |
|------|----------|--------------|
| `-i` | Входной Markdown-файл | обязательный |
| `-o` | Выходной PDF-файл | `<input>.pdf` |
| `-t` | Тема | `professional` |
| `-l` | Landscape ориентация | portrait |

## Темы

| Тема | Назначение |
|------|-----------|
| `professional` | Деловые документы, отчёты |
| `modern` | Техническая документация, код |
| `academic` | Научные статьи |
| `dark` | Тёмный режим |
| `minimal` | Чистый минималистичный вывод |

## Тесты

```bash
bash scripts/test_convert.sh
```

## Лицензия

MIT
