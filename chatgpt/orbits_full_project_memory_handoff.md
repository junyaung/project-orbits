# ORBITS / Cat Rescue Orbit Adventure — Full Conversation Memory Handoff

> 이 문서는 현재까지의 대화를 클리어하기 전에, 다음 대화에서 바로 이어갈 수 있도록 만든 **전체 프로젝트 메모리 / 개발 핸드오프 파일**이다.  
> 이 파일을 다시 ChatGPT 또는 Claude에게 업로드하면, 지금까지 무엇을 만들었고 어떤 방향으로 가고 있었는지 바로 이해할 수 있어야 한다.

---

## 0. 앞으로 답변할 때의 기본 스타일

- 사용자 Jun은 한국어로 실무적인 조언을 선호한다.
- 과한 칭찬이나 무조건적인 동의보다 **객관적이고 전문적인 판단**을 원한다.
- 게임 개발 방향에 대해서는 “좋다/나쁘다”보다 **왜 그런지, 어떤 리스크가 있는지, 어떻게 보완할지**를 원한다.
- 답변은 친근하지만 전문적으로.
- Claude에게 전달할 내용은 **복사/붙여넣기 가능한 markdown 지시문** 형태를 선호한다.
- 이미지 생성용 프롬프트는 **공용 프롬프트 따로 + 본문 따로**보다, 최근에는 **각 이미지/맵마다 한 번에 복붙 가능한 완결형 프롬프트**를 선호했다.
- PDF/MD/ZIP 파일로 정리해주는 것을 자주 요청한다.
- 현재 프로젝트는 Godot 4.x 기반으로 생각하고 있다.

---

# 1. 게임의 현재 핵심 정체성

## 1.1 초기 핵심 게임 컨셉

처음 아이디어는:

> 플레이어가 작은 캐릭터를 조작해, 행성 중력에 붙었다가 release하면서 위로 계속 올라가는 2D vertical mobile game.

핵심 조작:

```text
Hold screen = 현재 행성 주변을 orbit
Release = 현재 궤도 방향으로 launch
다음 행성 중력권에 들어가면 capture
목표 = 더 멀리 / 더 높이 이동
```

초기 주인공은 개구리 같은 레퍼런스도 있었지만, 곧 기본 주인공은 **고양이**로 정리되었다.

---

## 1.2 현재 핵심 fantasy

현재 가장 강한 게임 fantasy는:

> 길을 걷던 고양이가 맨홀 뚜껑을 밟고, 물압/폭발적인 힘으로 하늘과 우주로 날아간다.  
> 고양이는 파란 맨홀 뚜껑을 타고 행성 중력과 궤도를 이용해 우주를 여행한다.

기억해야 할 핵심 이미지:

```text
작은 고양이 + 파란 맨홀 뚜껑 + 하늘/우주 + 행성 궤도 여행
```

이것이 게임의 visual hook이다.

---

## 1.3 현재 장르 방향

처음에는 pure orbit runner / endless upward game이었다.

이후 사용자가 Strikers 1945 같은 vertical shooter로 바꾸고 싶은 충동을 이야기했다.  
객관적으로 분석한 결론은:

```text
완전한 Strikers 1945식 슈팅 게임으로 전환 ❌
기존 orbit/slingshot runner를 그대로만 유지 △
Orbit Shooter 하이브리드 ✅
```

추천 최종 장르 방향:

> **Cozy Cat Rescue Orbit Shooter / Orbit Adventure**  
> 이동은 orbit/slingshot이 핵심이고, 공격은 고양이별 자동 공격 또는 perfect sling 기반 스킬로 붙인다.

중요한 원칙:

```text
총 쏘려고 orbit하는 게임 ❌
orbit을 잘하면 공격도 멋지게 나가는 게임 ✅
```

즉, 전투 요소가 들어가더라도 게임의 주인공은 여전히 **orbit mechanic**이어야 한다.

---

# 2. 고양이 전용 rescue collection 컨셉

## 2.1 여러 동물 vs 고양이 전용

초기에는 여러 animal travelers를 생각했다:

- Cat
- Bunny
- Turtle
- Fox
- Bird
- Otter
- Hamster
- Raccoon

그러나 사용자가 “여러 동물이 아니라 고양이로만 한정하고, 각 지역에 홀로 남겨진 고양이를 구출해 스킨/캐릭터로 얻는 구조”를 제안했다.

객관적 판단:

> **여러 동물보다 고양이 전용 rescue collection 방향이 더 강할 가능성이 높다.**

이유:

1. 브랜드 문장이 더 선명하다. `하수구 뚜껑 타고 우주에서 고양이 구출하는 게임`
2. 고양이를 “사는” 것보다 “구출해서 데려오는” 구조가 감정적으로 강하다.
3. Cat Haven / Cat Room / Cat Log 같은 meta system과 잘 맞는다.
4. Shop은 고양이 자체를 파는 곳이 아니라, 구출한 고양이를 꾸미는 곳이 되면 훨씬 부드럽다.

---

## 2.2 현재 최종 narrative pitch

현재 가장 좋은 한 줄 pitch:

> **하수구 뚜껑을 타고 우주에 날아간 고양이가, 각 우주 지역에 길을 잃고 머물던 다른 고양이들을 하나씩 찾아 Cat Haven으로 데려오는 cozy orbit adventure.**

톤은 “버려진 고양이 구조”처럼 너무 슬프면 안 된다. 추천 톤:

```text
불쌍한 고양이 ❌
우주에서 길을 잃은 작은 고양이 ✅
별을 기다리던 고양이 ✅
행성에서 조용히 살던 고양이를 친구로 데려옴 ✅
```

---

## 2.3 Cat systems 이름

추천 시스템명:

```text
Cat Haven       = 고양이들이 머무는 방 / home room
Cat Log         = 구출한 고양이 도감
Rescue Signal   = 각 biome 끝 또는 milestone에서 고양이 구출 이벤트
Star Room       = 꾸미기 방
Cats            = 하단 navigation label
```

“Travelers”는 cat-only 방향을 택하면 더 이상 쓰지 않는 편이 좋다.  
Bottom nav 추천:

```text
Home
Star Path
Cats
Shop
Settings
```

---

## 2.4 고양이 차별화 기준

고양이만 나오면 전부 비슷해 보일 위험이 있다. 각 고양이는 단순 색깔만 다르게 하지 말고 최소 네 가지 요소가 달라야 한다.

```text
1. 외형 / 실루엣
2. 성격
3. 발견된 biome
4. Cat Haven 안에서 하는 행동
```

예시:

| Cat | 발견 장소 | 성격 | Cat Haven 행동 |
|---|---|---|---|
| Mochi | Upper Sky / 기본 | 호기심 많음 | 구름 쿠션에서 잠 |
| Bloom | Pastel Galaxy Garden | 몽환적 | 꽃 소용돌이 장난감과 놂 |
| Kumo | Kuiper Belt | 조용함 | 얼음별 옆에 앉음 |
| Vanta | Void Zone | 겁 많지만 충성스러움 | 어두운 구석에서 눈만 반짝임 |
| Lumen | Tachyon Drift | 활발함 | 빠르게 뛰어다님 |
| Tempo | Chrono Sea | 리듬감 있음 | 시계빛 모래를 바라봄 |
| Singa | Singularity Dream | 신비로움 | 중력방울을 관찰함 |
| Dream Cat | Final Dream Beyond | 궁극적/환상적 | 빛 속에서 천천히 떠 있음 |

---

## 2.5 Shop 방향

상점에서 고양이 자체를 직접 파는 구조는 피하는 것이 좋다.

추천:

```text
고양이를 돈 주고 사는 곳 ❌
구출한 고양이를 꾸미는 곳 ✅
방을 꾸미는 곳 ✅
탈것/cover/trail을 꾸미는 곳 ✅
```

팔 수 있는 것:

- cat hats
- scarves
- collar charms
- manhole cover skins
- trail effects
- Cat Haven furniture
- room backgrounds
- toys
- photo frames


---

# 3. 아트 방향

## 3.1 초기 최종 아트 방향

처음에는 “soft pastel watercolor storybook space”로 잡았다.

키워드:

```text
soft pastel watercolor
storybook
dreamy sky-space
muted navy-gray text
cream parchment UI
pale blue-gray panels
gentle shadows
cute but not childish
elegant, quiet, memorable
```

피해야 할 것:

```text
loud arcade
neon sci-fi
glossy plastic
aggressive monetization UI
harsh black outlines
realistic space photography
overly dark horror
```

---

## 3.2 Cats & Soup 스타일 참고 후 수정된 UI 방향

사용자가 Cats & Soup 같은 시안이 더 “게임답고 컨셉에 맞다”고 느꼈다.  
객관적 판단:

> 그 방향이 더 commercial하고, mobile game UI로 읽히는 힘이 더 강하다.

하지만 주의:

```text
Cats & Soup clone ❌
Cozy stitched watercolor orbit cat adventure ✅
```

최종 UI/UX 아트 방향명:

> **Cozy Watercolor Space Adventure UI**  
> 또는  
> **Cozy Stitched Watercolor Orbit Cat Adventure UI**

유지할 것:

- 둥근 stitched panel
- cream parchment buttons
- cute cat characters
- soft watercolor planets
- constellation style Star Path
- warm shop/travel UI
- large Launch button
- cozy + premium feeling

강화할 ORBITS 고유 motif:

- blue manhole cover
- orbit rings
- dotted orbit path
- soft stars
- strange biomes
- rescued cats
- Cat Haven
- Launch / Drift / Orbit language

줄일 것:

- 지나친 시골마을 / cooking game 느낌
- 너무 많은 꽃 장식
- 지나친 event / bundle 압박
- screen-filling shop UI
- direct Cats & Soup imitation

---

# 4. UI/UX 시스템

## 4.1 Home screen의 역할

Home은 단순 메뉴가 아니라:

> **cozy launch hub**

Home에서 유저가 느껴야 하는 감정:

```text
내가 돌아왔다.
구출한 고양이들이 있다.
업그레이드할 게 있다.
다시 한 번 launch하고 싶다.
```

Home의 시선 흐름:

```text
1. 선택된 고양이 + 파란 맨홀 뚜껑
2. 큰 Launch button
3. Star Path upgrade ready / progression hint
4. Event / Daily / Quests
5. Currency / Best Distance
6. Bottom navigation
```

---

## 4.2 Home background를 최고 도달 biome으로 바꾸는 아이디어

사용자가 Home screen으로 돌아왔을 때, 유저가 도달한 map의 background가 Home 배경으로 나오면 어떨지 물었다.

객관적 판단:

```text
Gameplay background를 그대로 Home에 깔기 ❌
해금한 biome의 분위기를 반영한 muted Home theme로 적용 ✅
```

추천 방식:

- Home background = highest reached biome 기준
- 단, gameplay intensity는 줄인다.
- brightness +10~20%
- contrast -20~30%
- saturation -10~20%
- particles 줄이기
- Launch button 주변 safe zone 유지

더 좋은 구조:

```text
기본값: highest reached biome 자동 적용
옵션: 유저가 원하는 Home Theme로 고정 가능
```

---

## 4.3 Claude가 만든 Home screen 피드백

사용자가 Claude에게 만든 Home screen을 보여줬다.

현재 Claude version 장점:

- Launch CTA가 잘 보임
- 전체가 깔끔함
- 고양이와 맨홀 뚜껑이 중심에 있음
- 읽기 쉬움

하지만 승인한 시안과 다른 점:

```text
1. 너무 비어 보임
2. 세계관 표현 약함
3. launch hub라기보다 단순 메뉴처럼 보임
4. meta system / event / current cat feeling이 부족함
```

가장 큰 문제:

```text
배경이 plain sky wash라서 generic하게 느껴짐.
```

시안은:

- starry sky
- small planets
- orbit dotted path
- lower meadow/base edge
- event card
- current traveler panel
- richer launch hub density

수정 방향:

```text
현재 버전의 clarity 유지
+ 시안의 worldbuilding density 추가
```

---

## 4.4 Home revision에 필요한 새 이미지

새로 만들 필요가 있다고 정리한 이미지:

1. Home hub background
2. Event banner illustration
3. Mini planet set
4. Orbit / decorative space motifs
5. Daily / Quests side illustration assets
6. Bottom navigation icon set
7. Star Path upgrade thumbnail

사용자가 이후 말하길 Current Cat Preview Art / Current Cover Preview Art는 만들지 않았으므로 최종 Claude 지시문에서 제외했다.

---

## 4.5 Home 최종 통합 MD 지시문

사용자에게 Claude용 최종 MD 지시문을 제공했다. 핵심 내용:

- 현재 Home을 완전 갈아엎지 말고, clarity는 유지한다.
- plain sky background는 바꾼다.
- Home-specific background를 사용한다.
- Event card를 upper-left에 추가한다.
- Daily / Quests를 left side에 유지한다.
- Star Path upgrade ready card를 Launch 위에 둔다.
- Bottom nav: Home / Star Path / Cats / Shop / Settings
- Current Cat / Current Cover preview는 현재 없으므로 mandatory requirement로 넣지 않는다.
- Right side는 무리하게 panel을 넣지 말고 balance/decorative composition으로 해결한다.

---

# 5. Production-ready UI/UX asset prompts

사용자가 mockup이 아니라 실제 Godot에 넣을 production-ready 2D UI/UX sprite assets를 원했다.

이에 따라 다음 asset sheet prompt들을 만들었다.

## 5.1 Core UI Kit

포함 요소:

- large primary Launch button states
- medium / small capsule button states
- circular icon button states
- utility buttons: close, back, plus, info, settings, reset, filter, dropdown
- panels: modal, popup, home card, shop item card, cat/traveler card, upgrade detail
- plaques: title, section header, name plaque
- navigation: bottom nav, selected tab, notification dot
- badges: new, owned, equipped, locked, max level, upgrade available, best value, limited, current, selected

중요 조건:

```text
No readable text
No numbers
No labels
Transparent background preferred
Isolated assets only
Godot Label nodes로 텍스트 추가
```

## 5.2 Gameplay HUD asset sheet

포함 요소:

- star counter chip
- distance plaque
- best distance plaque
- pause button
- heat bar frame/fills
- warning banner
- perfect sling badge
- new best badge
- shield/boost/magnet badges
- tutorial panels
- hand gesture holders
- orbit/release instruction frames
- retry/home/resume button backgrounds

## 5.3 Icon Set

공통 아이콘:

- Home
- Star Path
- Cats / Travelers
- Shop
- Settings
- Collection
- Worlds
- Back
- Close
- Info

Gameplay icons:

- Launch
- Orbit
- Drift
- Pause
- Retry
- Distance
- Heat
- Overheat warning

Upgrade icons:

- Launch Power
- Gravity Grip
- Perfect Sling
- Heat Capacity
- Cool Drift
- Shield Bubble
- Star Magnet
- Bonus Star
- Lucky Drift
- Meadow Drift
- Tachyon Flow
- Wormhole Balance

## 5.4 Star Path Skill Tree asset sheet

포함 요소:

- locked / available / unlocked / selected / maxed star nodes
- central cat / manhole cover node
- selected glow
- upgrade available glow
- dotted constellation path
- glowing connection line
- locked/completed connection line
- orbit ring circle/arc
- branch icon frames: Flight / Survival / Stars / Worlds
- selected upgrade detail panel
- cost chip
- upgrade button

## 5.5 Shop asset sheet

상점은 aggressive monetization이 아니라 “gentle space travel supply shop”처럼 보여야 한다.

포함 요소:

- shop main panel
- featured banner
- category tabs
- item cards: normal, selected, owned, equipped, locked, sold out, new
- bundle card
- price chips
- buy button states
- badges: new, limited, best value, popular, event
- frames for cover/trail/cat/bundle
- restore purchases button

## 5.6 Cats / Travelers asset sheet

초기에는 Travelers로 작성했지만, cat-only 방향에서는 Cats / Cat Haven으로 바꾸는 것이 좋다.

포함 요소:

- Cats title plaque
- selected cat preview panel
- cat info card
- cat story panel
- passive ability panel
- cat card states: normal, selected, owned, locked, new, rare/dream
- portrait frame
- selected outline
- equip/equipped buttons
- rarity badges
- paw/star/orbit decorations

## 5.7 Result / Popup / Modal asset sheet

포함 요소:

- Splashdown result panel
- distance/star/perfect sling statistic rows
- new best badge
- retry/home/resume/continue buttons
- pause modal
- reward modal
- confirmation dialog
- sleepy cat frame
- orbit swirl / paw / manhole motif

Death/result screen은 harsh Game Over가 아니라 “Splashdown”처럼 부드럽게.


---

# 6. Upgrade / Star Path 시스템

## 6.1 Skill tree 방향

사용자가 Path of Exile / Helldivers 같은 skill tree를 물었다.

객관적 판단:

```text
POE식 거대한 스킬트리 ❌
작은 constellation-style Star Path ✅
```

추천 이름:

- Star Path
- Orbit Atlas

최종적으로 Star Path가 감성적으로 더 좋다고 봤다.

---

## 6.2 Star Path branch

추천 branch:

```text
Flight
Survival
Stars
Worlds
```

### Flight

- Launch Power
- Gravity Grip
- Perfect Sling
- Orbit Control

### Survival

- Heat Capacity
- Cool Drift
- Warning Sense
- Shield Bubble
- Second Chance

### Stars

- Star Magnet
- Lucky Drift
- Bonus Star
- Combo Reward
- Treasure Orbit

### Worlds

- Meadow Drift
- Galaxy Glide
- Kuiper Calm
- Void Sense
- Wormhole Balance
- Tachyon Flow

---

## 6.3 MVP upgrades

MVP로 추천했던 upgrades:

1. Launch Power
2. Gravity Grip
3. Heat Capacity
4. Cool Drift
5. Star Magnet
6. Shield Bubble
7. Meadow Drift

수치 예시:

```text
Launch Power: +3%, +6%, +9%
Gravity Grip: +3%, +6%, +9%
Heat Capacity: +5%, +10%, +15%
Cool Drift: +5%, +10%, +15%
Star Magnet: +8%, +16%, +24%
Meadow Drift: Lv1 -2% Meadow heat gain → Max -15%
```

---

## 6.4 Upgrade card issue

사용자가 생성한 upgrade card에 “MEADOW RUN - LEVEL 3” 같은 baked text가 있었다.

피드백:

```text
Readable text를 이미지에 박으면 안 됨.
Godot Label로 넣어야 함.
```

추천 scene structure:

```text
UpgradeCard.tscn
├── CardBackground
├── UpgradeIcon
├── TitleLabel
├── LevelLabel
├── EffectLabel
├── NextEffectLabel
├── CostIcon
├── CostLabel
└── UpgradeButton
    └── ButtonLabel
```

“Meadow Run”보다 “Meadow Drift” 추천.

---

# 7. Result Popup / Death UI

현재 result popup screenshot에 대해 피드백했다.

기존 result popup:

- sleeping cat on manhole cover
- title: Splashdown
- distance: 1831m
- new best
- star/perfect count
- button: Drift Again

문제:

```text
new best label이 flavor text와 겹침.
```

추천 layout:

```text
[cat sleeping]
Splashdown
“Off into the quiet blue —
 a new planet waits.”

✦ new best ✦
1831 m

★ 51    ✧ 0 perfect

[Drift Again]
[Home] secondary
```

Death/result는 gentle해야 함. “Game Over”보다는 “Splashdown”이 좋다.

---

# 8. Background / Map / Biome 시스템

## 8.1 기본 원칙

사용자가 만든 background 한 장이 약 100–120m 정도라고 했다.  
Biome 하나를 1500m로 잡으면 한 이미지를 13–15번 반복해야 하는 문제가 생긴다.

결론:

> 1500m 구간을 배경 이미지 1장으로 해결하면 안 된다.  
> 한 biome = 여러 visual module 조합으로 해결해야 한다.

추천 구조:

```text
1 biome =
- seamless base background 4장
- overlay effect 2종
- decor asset 6–10개
- special gimmick visual 1–2개
- transition visual 1개
```

단, Upper Sky에서는 실제로 다음으로 줄였다:

```text
Base A, B, C
Overlay 1
Decor set
Gimmick 1, 2
Transition visual
```

---

## 8.2 Background layer system

Godot 구조 추천:

```text
Layer 0: far background wash
Layer 1: main background tile
Layer 2: mid decorative forms
Layer 3: moving particles / mist / effects
Layer 4: foreground soft accents
```

또는 biome node 구조:

```text
AnimatedBiomeBackground.tscn
├── BaseBackground
├── OverlayLayerA
├── OverlayLayerB
├── AccentContainer
├── SlowDustParticles
├── FastStreakParticles
├── GlowParticles
└── SoftTint
```

Biome background는 gameplay용과 Home용을 구분해야 한다.

---

## 8.3 Biome progression philosophy

중요한 원칙:

> 각 맵은 예쁜 배경이 아니라, 하나의 새로운 플레이 감각이어야 한다.

각 biome은:

```text
1. Introduce: 새 기믹을 안전하게 보여줌
2. Practice: 기믹을 2~3번 연습
3. Combine: 이전 기믹과 섞음
4. Test: 조금 어려운 패턴으로 마무리
```

---

# 9. 현재/예정 biome 목록

## 9.1 스크린샷에 있었던 현재 map files

사용자가 보여준 map list:

```text
map_black hole cathedral_11.png
map_crystal aurora expanse_6.png
map_dark matter reef_17.png
map_dimensional lattice_15.png
map_dream sky_1.png
map_entropy field_19.png
map_event horizon veil_14.png
map_Forgotten Orbit Ruins_7.png
map_oort cloud_4.png
map_quantum foam abyss_12.png
map_supernova remnant bloom_13.png
map_tachyon drift_18.png
map_upper sky_0.png
map_void zone_5.png
map_wormhole garden_16.png
```

## 9.2 없었던 map

그 당시 missing이라고 정리한 것:

```text
Pastel Galaxy Garden
Kuiper Belt
Time-Space Distortion / Rift Zone
Singularity Dream
Final Dream Beyond
Chrono Sea
```

이후 Pastel Galaxy Garden, Kuiper Belt, Singularity Dream, Final Dream Beyond, Chrono Sea에 대한 프롬프트를 작성했다.

## 9.3 다시 만들어야 한다고 했던 맵

사용자가 명확히 “다시 만들어야 한다”고 했던 핵심 맵:

```text
Pastel Galaxy Garden
Kuiper Belt
```

추가 개선 후보:

```text
Singularity Dream
Final Dream Beyond
Tachyon Drift loop version
Chrono Sea
Black Hole Cathedral subtle cathedral version
```

---

# 10. Biome level design / 거리표

## 10.1 전체 distance design 1차안

추천했던 전체 거리표:

| 거리 | Biome | 역할 | 핵심 기믹 |
|---:|---|---|---|
| 0–300m | Upper Sky | 조작 튜토리얼 | 기본 orbit / release |
| 300–800m | Dream Sky | 기본 재미 안정화 | heat, star route |
| 800–1,400m | Pastel Galaxy Garden | 보상 루트 수업 | 꽃가루 흐름, curved reward path |
| 1,400–2,100m | Kuiper Belt | 장애물 타이밍 | 얼음 파편, 좁은 통로 |
| 2,100–2,900m | Oort Cloud | 시야/거리감 | 안개, 늦게 보이는 행성 |
| 2,900–3,800m | Crystal Aurora Expanse | 반응/각도 | 반사 광선, crystal orbit |
| 3,800–4,800m | Void Zone | 불확실성 | 어두운 영역, ghost planet |
| 4,800–5,900m | Forgotten Orbit Ruins | 구조물 회피 | 폐허 링, broken orbit gate |
| 5,900–7,100m | Dark Matter Reef | 공간 압박 | shadow reef, slow pull zone |
| 7,100–8,500m | Wormhole Garden | 공간 이동 | wormhole pair |
| 8,500–10,000m | Tachyon Drift | 속도 증가 | speed current |
| 10,000–11,700m | Entropy Field | 시간 제한 압박 | disappearing planets |
| 11,700–13,500m | Chrono Sea | 리듬/타이밍 | time tide, slow/fast pulse |
| 13,500–15,500m | Supernova Remnant Bloom | 폭발 패턴 | expanding shockwave |
| 15,500–17,700m | Event Horizon Veil | 중력 압박 | strong pull, escape window |
| 17,700–20,100m | Black Hole Cathedral | 정교한 회피 | gravity arch lanes |
| 20,100–22,800m | Quantum Foam Abyss | 예측/반응 | blinking micro planets |
| 22,800–25,800m | Dimensional Lattice | 패턴 이해 | grid portal / mirrored lanes |
| 25,800–30,000m | Singularity Dream | 종합 시험 | warped gravity + mixed mechanics |
| 30,000m+ | Final Dream Beyond | 최종/무한 영역 | mastery remix |

## 10.2 MVP biome 추천

전체 20개를 처음부터 구현하지 말고, MVP는 7개 biome로 시작 추천:

| 거리 | Biome | 기믹 |
|---:|---|---|
| 0–300m | Upper Sky | 기본 조작 |
| 300–900m | Pastel Galaxy Garden | 보상 루트 |
| 900–1,600m | Kuiper Belt | 장애물 타이밍 |
| 1,600–2,500m | Void Zone | 시야/ghost planet |
| 2,500–3,700m | Wormhole Garden | wormhole |
| 3,700–5,200m | Tachyon Drift | speed current |
| 5,200m+ | Singularity Dream | 종합 remix |

## 10.3 Upper Sky design

Upper Sky는 0–300m 추천.

내부 구성:

```text
0–80m      거의 실패 불가능
80–180m    release 타이밍 연습
180–300m   첫 번째 가벼운 위험 요소 또는 reward path
```

최근 Upper Sky implementation brief에서는 다음으로 수정:

```text
0m–100m      Intro / safe learning
100m–200m    Basic orbit + release practice
200m–270m    Gentle reward-path practice
270m–300m    Transition into next biome
```

목표:

```text
Hold = orbit
Release = launch
Star trail = 좋은 방향
Long orbit = heat risk
```


---

# 11. Biome별 gameplay gimmick 정리

## Upper Sky
역할: 기본 조작 학습  
기믹: 거의 없음 / gentle wind current / perfect sling star trail cue  
위험: 거의 없음  
목표: hold/release/orbit 이해

## Dream Sky
역할: 기본 재미 안정화  
기믹: heat + star reward route  
감정: 조금 욕심내면 더 먹을 수 있는데 위험하다.

## Pastel Galaxy Garden
역할: reward route 선택  
기믹: 꽃가루 current / curved reward path  
장애물: petal cloud, bloom obstacle  
톤: 가장 예쁜 인기맵

## Kuiper Belt
역할: obstacle timing  
기믹: icy debris belt  
학습: 얼음 파편이 지나갈 때까지 기다렸다 release  
주의: 빠른 반응보다 timing 판단

## Oort Cloud
역할: visibility / uncertainty  
기믹: fog, hidden planets  
주의: “안 보여서 죽음”이 아니라 힌트를 읽게 해야 함

## Crystal Aurora Expanse
역할: angle / reaction  
기믹: aurora beam, prism reflection  
주의: beam은 예고 glow 필요

## Void Zone
역할: psychological pressure  
기믹: ghost planet, darkness  
주의: readable darkness

## Forgotten Orbit Ruins
역할: structure navigation  
기믹: broken orbit gate, ruin rings  
감정: 공간 퍼즐

## Dark Matter Reef
역할: spatial pressure  
기믹: shadow reef, dark pull  
오래 기다리면 점점 압박

## Wormhole Garden
역할: spatial teleport  
기믹: paired wormholes  
처음에는 color-coded entrance/exit

## Tachyon Drift
역할: speed adaptation  
기믹: speed current  
주의: 빠르지만 capture assist 약간 관대하게

## Entropy Field
역할: quick decision  
기믹: decay planets / disappearing planets  
heat tension 강화

## Chrono Sea
역할: rhythm timing  
기믹: time tide slow/fast pulse  
clock motif는 은은하게

## Supernova Remnant Bloom
역할: expanding pattern dodge  
기믹: shockwave  
예고가 명확해야 함

## Event Horizon Veil
역할: gravity pressure  
기믹: pull / escape velocity  
잘못된 angle이면 휘어짐

## Black Hole Cathedral
역할: curved safe lane  
기믹: gravity arch lane  
성당은 literal building이 아니라 은은한 arch/column feeling

## Quantum Foam Abyss
역할: prediction / reaction  
기믹: blinking micro planets  
0.5–1초 전 shimmer cue 필요

## Dimensional Lattice
역할: pattern recognition  
기믹: mirrored lane / grid portal

## Singularity Dream
역할: 종합 시험  
기믹: 이전 기믹 remix

## Final Dream Beyond
역할: final mastery / score attack  
기믹: 아름다운 mastery remix  
너무 지옥맵처럼 만들지 말 것

---

# 12. Map prompt summaries

## 12.1 Pastel Galaxy Garden prompt 방향

완결형 프롬프트를 만들었다.

핵심:

```text
soft pastel watercolor celestial flower garden
outer-space biome
lavender, lilac, blush pink, pale peach, mint, baby blue
soft nebula clouds
pastel galaxy swirls
floating petal-like cosmic shapes
flower-inspired space forms
tiny glowing stars
gold dust
drifting pollen-like stardust
```

목표:

```text
감탄 / 인기맵 / 예쁜 초중반 transition biome
```

피할 것:

```text
realistic astronomy
harsh neon
large single center planet
blank center
overly flat
```

---

## 12.2 Kuiper Belt prompt 방향

핵심:

```text
cold quiet mysterious outer-space biome
icy bodies
dusty frozen fragments
distant pale cosmic light
icy blue, pale cyan, silvery white, muted lavender
frozen dust belts
small/medium icy fragment clusters near edges
faint crystalline debris
ring-like arc suggestions
```

목표:

```text
거리감 / 신비감 / frozen outer frontier
```

피할 것:

```text
large sharp asteroids dominating
cluttering center
harsh black emptiness
realistic space photography
```

---

## 12.3 Singularity Dream prompt 방향

핵심:

```text
hidden final-space biome
black hole energy
quantum shimmer
warped gravity
folded dimensional space
soft warped halos
folded-space veils
gravitational spirals
glow pockets
dimensional tension
```

목표:

```text
hidden final biome / deepest secret layer of universe
```

피할 것:

```text
realistic black hole photography
one giant central black hole
horror darkness
aggressive neon
```

---

## 12.4 Final Dream Beyond prompt 방향

핵심:

```text
ultimate final biome beyond all known space
color, memory, light, dreamlike cosmic emotion
pearl white, lavender, blush pink, soft cyan
iridescent aurora veils
rainbow mist
glow ribbons
light petals
opalescent glow pools
```

목표:

```text
true final biome / emotional beautiful ending
```

주의:

```text
too plain washed-out pastel fog가 되면 안 됨
structure와 depth 필요
```

---

## 12.5 Chrono Sea prompt 방향

처음 프롬프트는 warped clocks / clock hands가 너무 적나라하게 나왔다.  
이후 subtle hidden clock version으로 다시 작성했다.

최종 방향:

```text
time has become liquid
cosmic temporal ocean
faint circular ripple patterns that suggest clock faces
barely visible radial marks
dissolved clock-hand-like curves
partial circular arcs
soft ring ripples
hidden time motif
```

중요:

```text
시계가 보인다 ❌
시간의 흔적이 숨어 있다 ✅
```

느낌:

> “At first glance, beautiful cosmic ocean. After looking longer, faint clock-like arcs and temporal symbols appear.”

---

## 12.6 Black Hole Cathedral prompt 방향

사용자가 cathedral이 은은하게 보였으면 한다고 했다.

최종 방향:

```text
black hole gravity + sacred silence + faint cathedral-like forms
hidden holy place at edge of cosmic collapse
soft warped halos
curved gravitational veils
distant column-like silhouettes
arch-like silhouettes hidden in mist
abstract rose-window-like glow
rib-like curved structures
```

중요:

```text
literal cathedral building ❌
space itself feels cathedral-like ✅
```

피할 것:

```text
clear church facade
doors/windows
large crosses
heavy gothic detail
one giant black hole
horror darkness
```

---

## 12.7 Black Hole Cathedral 이미지 naming

사용자가 실제 map_black hole cathedral 이미지를 보여주고 이름을 물었다.

판단:

> 해당 이미지는 cathedral보다 Event Horizon Veil에 더 잘 맞았다.

추천 이름:

```text
Event Horizon Veil
Gravity Veil
Abyssal Halo
Black Tide Halo
Eclipse Veil
```

가장 추천:

```text
Event Horizon Veil
```

이유:

- 건축적이지 않음
- 성당/기둥/아치 느낌 약함
- 대신 사건의 지평선, 빛의 장막, 중력 왜곡 느낌 강함

만약 Black Hole Cathedral로 쓰려면 architecture hint를 더 추가해서 다시 만들어야 한다.

---

# 13. Upper Sky asset system

## 13.1 사용자가 새로 만든 Upper Sky assets

사용자가 만든 asset list:

```text
1_map_upper sky_A.png
1_map_upper sky_B.png
1_map_upper sky_C.png
1_map_upper sky_overlay effect.png
1_map_upper sky_decor set.png
1_map_upper sky_gimmick visual_gentle wind current lane.png
1_map_upper sky_gimmick visual_perfect sling star trail cue.png
1_map_upper sky_transition visual.png
```

Base A/B/C는 비슷하지만 미묘하게 다르고, overlay/decor/gimmick/transition으로 더 생동감 있게 만들 수 있다.

---

## 13.2 Upper Sky Claude implementation file

사용자가 Claude에게 줄 수 있도록 MD 파일을 만들었다:

```text
upper_sky_biome_implementation_brief_for_claude.md
```

주요 내용:

- Upper Sky = 0–300m
- Phase 1: 0–100m Base A
- Phase 2: 100–200m Base B
- Phase 3: 200–270m Base C
- Phase 4: 270–300m Base C + transition visual
- overlay alpha 0.20 → 0.35
- decor density low → medium
- wind current lane = helper path
- perfect sling star trail cue = ideal release angle cue
- particles:
  - UpperSkyDustParticles
  - CloudMistParticles
- Node structure:
  - BackgroundRoot
  - BaseSegmentContainer
  - TransitionLayer
  - OverlayLayer
  - DecorLayer
  - ParticleLayer
  - GameplayCueLayer

---

## 13.3 Upper Sky implementation 핵심

Upper Sky는 “예쁜 배경 3장 반복”이 아니라:

```text
Base A/B/C
+ overlay slow drift
+ decor parallax
+ tutorial cue visuals
+ transition visual
+ subtle particles
```

으로 구성해야 한다.

Upper Sky가 가르쳐야 하는 것:

```text
Hold = orbit
Release = launch
Star trail = good route
Wind current = helpful path
Perfect release = better reward
```

금지:

```text
fast meteors
aggressive enemies
dark zones
disappearing planets
strong gravity distortion
```

---

# 14. Tachyon Drift animation / seamless loop

Tachyon Drift를 Higgsfield/Kling 등으로 image-to-video loop 만들려고 시도했다.

문제:

```text
AI video는 첫 프레임/마지막 프레임이 잘 맞지 않아 seamless gameplay background로 불안정함.
```

한 번 ping-pong loop workaround 파일을 만들었다:

```text
tachyon_drift_pingpong_loop.mp4
```

하지만 결론:

```text
AI video는 gameplay background보다는 title screen, biome reveal, unlock cutscene, special portal에 적합.
Gameplay 배경은 PNG + particles / overlays / Godot procedural animation이 더 안전.
```

Tachyon Drift animation 방향:

- static background
- fast cyan streak particles
- small glowing particles
- locked camera
- no zoom/pan
- loop not via video, but via Godot particles/overlays

---

# 15. Godot implementation notes

## 15.1 CatVehicle scene

초기 추천 구조:

```text
CatVehicle.tscn
├── Node2D
├── Shadow Sprite2D
├── ManholeCover Sprite2D
├── CatBody Sprite2D
├── CatHead Sprite2D
├── CatLeftPaw
├── CatRightPaw
├── CatTail
├── CatFace AnimatedSprite2D
├── LaunchTrail GPUParticles2D
├── SparkleParticles GPUParticles2D
└── AnimationPlayer
```

Animation:

- cat bobbing
- blink
- tail sway
- cover tilt/wobble
- launch trail
- sparkle

## 15.2 Planet scene

추천 구조:

```text
Planet.tscn
├── Area2D
├── SpriteBase
├── Face/StateOverlay
├── OrbitRing Line2D or Sprite
├── SteamParticles
├── CollisionShape2D
└── AnimationPlayer
```

Planet은 biome별로 property를 달리할 수 있음:

- gravity strength
- orbit speed
- heat gain
- capture radius
- special behavior

## 15.3 Gameplay HUD scene

추천 구조:

```text
GameplayHUD.tscn
├── CanvasLayer
├── TopBar
├── StarIcon/StarLabel
├── DistanceLabel
├── PauseButton
├── HeatBar TextureProgressBar
├── WarningBanner
└── TutorialLabel
```

HUD는 cozy stitched watercolor style로 하되 gameplay 중에는 가볍고 작아야 한다.

## 15.4 AnimatedBiomeBackground scene

추천 구조:

```text
AnimatedBiomeBackground.tscn
├── BackgroundRoot
│   ├── BaseBackground
│   ├── OverlayLayerA
│   ├── OverlayLayerB
│   ├── AccentContainer
│   ├── SlowDustParticles
│   ├── FastStreakParticles
│   ├── GlowParticles
│   └── SoftTint
```

Export variables:

```gdscript
@export var biome_type: BiomeType
@export var base_texture: Texture2D
@export var overlay_texture_a: Texture2D
@export var overlay_texture_b: Texture2D
@export var particle_texture_dot: Texture2D
@export var particle_texture_streak: Texture2D
@export var motion_intensity: float = 1.0
@export var background_scroll_speed: float = 0.0
```

Biome enum:

```gdscript
enum BiomeType {
    DREAM_SKY,
    WORMHOLE_GARDEN,
    TACHYON_DRIFT,
    DARK_MATTER_REEF,
    ENTROPY_FIELD
}
```

## 15.5 Biome animation presets

### Wormhole Garden

- spiral/flower wormholes slowly rotate/breathe
- tendrils sway
- mist drift
- small glowing dust
- Overlay rotation -1.5° to +1.5° over 8s
- Overlay scale 0.985 to 1.015 over 6s

### Tachyon Drift

- fast cyan streak particles diagonally
- small glowing particles fast
- no camera movement
- FastStreakParticles high velocity
- overlay alpha pulse 0.75–0.95 over 3s

### Dark Matter Reef

- shadow reef forms slowly sway
- teal particles float
- Overlay x drift -8px to +8px over 7s
- Overlay alpha 0.6–0.85 over 5s

### Entropy Field

- fading dust slow
- fragmented glow flicker gently
- subtle alpha pulse


---

# 16. Shooting / combat expansion notes

사용자가 vertical shooting game으로 바꾸고 싶은 충동을 이야기했다.

추천 하이브리드:

```text
Move = orbit/slingshot
Attack = automatic or perfect-sling-based
Skill = cat-specific
```

예시 cat attacks:

| Cat | Attack style |
|---|---|
| Mochi | balanced star shot |
| Lumen | fast straight laser |
| Bloom | pollen spread shot |
| Kumo | ice wave / slow |
| Vanta | homing dark orb |
| Echo | bouncing shot |
| Singa | gravity burst |

Monster/enemy는 “괴물 학살”보다 biome phenomenon처럼:

```text
Pastel Galaxy Garden: flower pollen ghost, lost star seed
Kuiper Belt: icy fragment spirit
Chrono Sea: time echo, second-hand ghost
Dark Matter Reef: shadow jellyfish
Wormhole Garden: spiral bug
Singularity Dream: gravity shard, dimensional echo
```

Boss는 cat을 막고 있는 cosmic phenomenon을 정화/돌파하는 느낌.

MVP combat test:

```text
한 맵에서만
- 기존 orbit movement 유지
- 자동 별탄 발사 추가
- 간단한 적 2종
- perfect sling 시 강화탄
- mini boss 1개
```

테스트 질문:

1. orbit 조작이 더 재밌어졌나?
2. 적을 쏘는 게 launch timing을 방해하나?
3. 화면이 복잡해졌나?
4. cat별 공격 차이가 수집 욕구를 만들 수 있나?
5. cozy 감성이 깨지나?

---

# 17. Files created during conversation

다음 파일들이 생성되었다. 실제 경로는 당시 sandbox 기준이다.

## 17.1 Claude handoff bundles

```text
orbits_claude_handoff.md
orbits_claude_handoff.pdf
orbits_claude_handoff_bundle.zip
```

초기 ORBITS handoff.

## 17.2 Cat rescue version

```text
orbits_cat_rescue_claude_handoff.md
orbits_cat_rescue_claude_handoff.pdf
orbits_cat_rescue_claude_handoff_bundle.zip
```

Cat rescue / Cat Haven 방향으로 업데이트된 handoff. PDF는 51페이지로 확인됨.

## 17.3 Home revision brief

```text
orbits_home_screen_revision_brief.md
```

Claude Home screen 수정 지시문.

## 17.4 Upper Sky implementation brief

```text
upper_sky_biome_implementation_brief_for_claude.md
```

Upper Sky assets를 Godot/Claude가 어떻게 써야 할지 정리한 MD.

---

# 18. 현재 가장 중요한 project direction

현재까지의 대화 기준으로 가장 좋은 방향은:

> **Cozy Cat Rescue Orbit Adventure / Orbit Shooter hybrid**  
> 고양이가 파란 맨홀 뚜껑을 타고, 행성 중력을 이용해 위로 이동하고, 각 biome에서 길 잃은 고양이를 구출하며, Cat Haven에서 모으고 꾸미는 모바일 게임.

핵심 pillar:

```text
1. Orbit / release 조작의 독창성
2. 고양이 rescue collection의 감정적 동기
3. Cozy stitched watercolor UI/UX
4. 다양한 biome + 각 biome별 gameplay gimmick
5. Star Path progression
6. Cat Haven / room customization
7. 필요하면 automatic orbit shooter combat를 가볍게 추가
```

---

# 19. 앞으로의 우선순위

## 19.1 가장 가까운 next steps

1. Upper Sky implementation을 Claude/Godot에 적용
2. Upper Sky가 실제로 “살아있는 tutorial biome”처럼 느껴지는지 테스트
3. Pastel Galaxy Garden full asset set 만들기
4. Kuiper Belt full asset set 만들기
5. biome background manager / visual director 시스템을 Godot에 구축
6. Home screen을 revised Home hub 방향으로 다시 구성
7. Cat rescue flow / Cat Haven prototype 설계
8. Star Path MVP upgrade 구현
9. optional orbit shooter prototype 1맵 테스트

---

## 19.2 다음에 대화를 재개할 때 할 수 있는 요청 예시

이 파일을 읽은 후 다음과 같이 이어가면 된다:

```text
이 handoff 파일 읽고, Pastel Galaxy Garden도 Upper Sky처럼 base/overlay/decor/gimmick/transition prompt set 만들어줘.
```

또는:

```text
이 자료 기준으로 Godot에서 BiomeBackgroundManager.gd를 실제 코드로 만들어줘.
```

또는:

```text
Cat Haven 화면의 UI/UX와 production asset prompts를 만들어줘.
```

또는:

```text
Orbit Shooter를 테스트하기 위한 1주일 프로토타입 설계서를 만들어줘.
```

---

# 20. 핵심 판단 요약

마지막으로 중요한 판단만 압축하면:

```text
게임의 가장 강한 hook:
고양이 + 파란 맨홀 뚜껑 + orbit/slingshot + 우주 여행

가장 좋은 meta concept:
각 biome에서 길 잃은 고양이를 구출하고 Cat Haven에 모으기

가장 좋은 UI 방향:
Cats & Soup 느낌을 참고한 cozy stitched watercolor mobile UI, 그러나 절대 clone이 아니라 ORBITS 고유 motif 강화

가장 좋은 progression:
Star Path constellation skill tree + biome별 rescued cat + Cat Haven customization

가장 좋은 combat 방향:
완전 슈팅 전환은 위험. Orbit Shooter 하이브리드가 최선.

가장 좋은 background 제작 방식:
한 biome = base variants + overlay + decor + gimmick visuals + transition visual

가장 중요한 개발 원칙:
각 biome은 단순 배경이 아니라 하나의 gameplay lesson이어야 한다.
```

---

## End of Handoff

이 문서를 새로운 대화에 업로드하면, 다음 assistant는 이 프로젝트를 바로 이어받아야 한다.
