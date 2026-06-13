# static-ffmpeg-binaries

## Docs 운영 규칙

- 루트 CLAUDE.md 는 Quick References 인덱스로 유지하고, 긴 설명은 docs/README.md 또는 nested CLAUDE.md 로 라우팅한다.
- 변경 가능하거나 번복될 수 있는 결정은 CLAUDE.md 가 아니라 docs/ 에 기록한다.
- 장기/멀티세션 작업은 docs/ops/context/<작업명>-<YYYYMMDD>/PROGRESS.md 를 먼저 읽고 없으면 생성한다.
- PROGRESS.md 는 ## Done, ## In progress, ## Next, ## Notes 4섹션으로 유지한다.
- 복잡한 경계 디렉터리에는 Public Contracts / Boundary Rules / Verification 구조의 nested CLAUDE.md 를 둔다.
- 문서화된 인터페이스가 바뀌면 문서, 구현, 테스트를 함께 갱신한다.
