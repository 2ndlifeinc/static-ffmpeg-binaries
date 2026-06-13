# Docs

## Directory standard

```text
docs/
├── README.md
├── adr/
├── design/
├── ops/
│   ├── CLAUDE.md
│   ├── context/
│   ├── appendix/
│   │   ├── references/
│   │   ├── research/
│   │   ├── troubleshooting/
│   │   └── assets/
│   ├── archive/
│   ├── reverse-engineering/
│   └── security/
└── research/
```

## Routing

- Long-lived architecture decisions: `docs/adr/`
- Current implementation design: `docs/design/`
- Work logs, incidents, rollouts, handoffs: `docs/ops/context/<task>-<YYYYMMDD>/`
- External references: `docs/ops/appendix/references/`
- Raw research and comparisons: `docs/ops/appendix/research/`
- Troubleshooting runbooks: `docs/ops/appendix/troubleshooting/`
- Document assets: `docs/ops/appendix/assets/`
- Stale documents: `docs/ops/archive/`
- Reverse engineering evidence: `docs/ops/reverse-engineering/`
- Product/feature/OSS research conclusions: `docs/research/`
