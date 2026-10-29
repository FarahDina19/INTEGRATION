# Integral Buddy design notes (working file)

Repo: https://github.com/FarahDina19/INTEGRATION (static HTML Unit 3 Integration apps, DUM10092, IKM; Malay README). Managed game project: /home/ubuntu/intbuddy (Godot generic starter, Cloud, PORT 3000). Blueprint gbp_41d6bae74193bcd74cbaa771 approved rev 3: Standard effort, AI-generated assets, no mockups, offline, English only.

Style: hand-painted gouache picture-book; signature "integral teal" #2BB3A3, cream #FFF7EB, coral #FF8A73, dark teal ink #0E4A47.

Generated art (transparent unless noted), all in assets/art/:
- pet/stage{1,2,3}_{happy,sad}.png (1920^2). stage1 baby blob + leaf; stage2 two leaves + coral scarf; stage3 glasses, cape, flower.
- scenes/home.png, garden.png, chalkboard.png (opaque 2560x1440)
- items/apple.png muffin.png pie.png ball.png yarn.png
- TODO: items/kite.png, icons coin/heart/hunger/star, OG cover 1200x630 (assets/share/og.png), favicon (crop of stage1 head, assets/share/favicon.png)

Gameplay plan:
- Home: pet with Hunger + Joy needs (decay in real time while playing), coins, XP growth (3 stages), inventory, shop (3 foods, 3 toys).
- Study Desk: typed-answer integration challenges, topics: reverse diff, basic rules, substitution, by parts, partial fractions, definite. Numeric equivalence checking up to constant, +C detection, coefficient/sign feedback, 3 hints + worked steps.
- Mini-game 1 Antiderivative Catch (garden): move pet left/right (A/D, arrows), catch bubble with correct antiderivative.
- Mini-game 2 Area Pour (chalkboard): hold Space/mouse to sweep shaded area; release when area readout equals given definite integral.

## Delivery facts (2026-10-26)
- Target repo FarahDina19/INTEGRATION, clone at /home/ubuntu/INTEGRATION, branch main. GitHub Pages build_type=workflow (.github/workflows deploys whole repo root '.' on push to main). Live: https://farahdina19.github.io/INTEGRATION/ (no index.html yet -> landing page needed).
- Existing root files: README.md (Malay), 'Unit 3 Integration — Apps.html' (2.9MB canvas), 'Unit 3 · Integration — Apl Pembelajaran Interaktif.html' (main app, 3.1-3.4). Apps: A Undo Machine (3.1), B Rule Cards (3.2), D Area Hunter (3.4), C Technique Toolbox (3.3).
- Plan: add index.html landing + game export under game/integral-buddy/ (threads off -> works without COOP/COEP).
- Managed sharing origin: https://intbuddy-i3ee9ese.manus.game
- Status: 138 tests pass; loader restyled; OG at assets/share/og.png; favicon assets/share/favicon.png.
