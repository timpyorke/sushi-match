part of '../gen_prompts.dart';

const _characters = [
  // General customers: cust0–cust5 in lib/ui/l10n.dart.
  Character(
    file: '00-granny-sakura',
    en: 'Granny Sakura',
    th: 'คุณยายซากุระ',
    role: 'General customer `cust0` (any restaurant)',
    looks: 'a kind, small, elderly Japanese grandmother. White hair rolled '
        'into a round bun with a pink sakura-flower kanzashi hairpin. Eyes '
        'drawn as curved smiling lines (closed happy arcs), gentle smile, tiny '
        'wrinkles at the eye corners, pink cheeks. Pale pink kimono (#F8C8D4) '
        'with a small white sakura pattern, darker rose obi (#D9708A), white '
        'tabi socks and wooden geta sandals.',
    personality: 'Gentle, patient and warm, but fussy about freshness.',
    palette: {'kimono': '#F8C8D4', 'obi': '#D9708A'},
    pose: 'slightly hunched with hands folded in front',
    props: ['hairpin flower alone'],
    blink: 'eyes squeezed into a slightly deeper smile',
    talk: 'right hand raised palm-up in a kind explaining gesture',
    happy: [
      'small crouch to wind up, eyes as ^^ arcs.',
      'small hop off the ground, both hands clasped at the chest, extra rosy '
          'cheeks, two tiny pink sparkle hearts near the head.',
      'top of the hop, hairpin flower bouncing, big open smile.',
      'landed, big smile, one hand waving.',
    ],
    sad: [
      'smile fading, neutral mouth.',
      'eyebrows tilted up, small frown, eyes now open and glistening, looking '
          'down.',
      'head droops, shoulders slump, one small tear at the eye corner.',
      'same sad pose, one hand resting on the cheek.',
    ],
    gait: 'small shuffling elderly steps with a slight hunch, hands folded at '
        'the waist. Kimono sleeves and the hairpin flower sway a little.',
    signature: Anim(
        'bow',
        'greeting at level start',
        'play once at 8 fps',
        'Polite Japanese bow, side three-quarter view facing left, hands '
            'folded in front',
        [
          'standing upright, smiling.',
          'bowing forward about 20 degrees.',
          'bowing forward about 40 degrees, eyes closed.',
          'back up halfway, warm smile.',
        ]),
  ),
  Character(
    file: '01-mr-tanaka',
    en: 'Mr. Tanaka',
    th: 'คุณทานากะ',
    role: 'General customer `cust1` (any restaurant)',
    looks: 'a young Japanese office worker. Neat navy suit (#2F3E5C), white '
        'shirt, a crooked red necktie (#C8463D), round glasses, flat '
        'slicked-down black hair, faint tired shadows under the eyes, a brown '
        'leather briefcase (#7A4A2A).',
    personality: 'Always in a rush on a 15-minute lunch break; grumbles but is '
        'kind and tips when served on time.',
    palette: {'suit': '#2F3E5C', 'tie': '#C8463D', 'briefcase': '#7A4A2A'},
    pose: 'standing upright holding the briefcase, slightly impatient',
    props: ['briefcase', 'glasses alone', 'necktie alone'],
    talk: 'free hand pointing forward urgently',
    happy: [
      'relieved exhale, shoulders drop, small smile.',
      'small hop, thumbs up, glasses glinting.',
      'pushes glasses up with one finger, confident grin.',
      'landed, flips a small gold coin tip upward with a thumb, smiling.',
    ],
    sad: [
      'smile gone, eyebrows knitted.',
      'glances at the wristwatch, small sweat drop.',
      'shoulders slump, loosens the tie with one finger.',
      'sighs, a tiny grey cloud above the head, briefcase hanging low.',
    ],
    gait: 'brisk hurried fast-walk leaning forward, briefcase swinging and '
        'necktie flapping behind.',
    signature: Anim('watch', 'when moves are running low', 'loop at 8 fps',
        'Impatient watch check, front three-quarter view', [
      'raises the wrist to look at the wristwatch.',
      'stares at the watch, eyebrows down, glasses glinting.',
      'taps one foot, a small sweat drop on the forehead.',
      'looks up and forward, mouth open as if saying "hurry".',
    ]),
  ),
  Character(
    file: '02-little-mei',
    en: 'Little Mei',
    th: 'น้องเมย์',
    role: 'General customer `cust2` (any restaurant)',
    looks: 'a little Japanese girl about six years old. Two pigtails tied with '
        'big red bows (#E53935), big round sparkling eyes, a missing front '
        'tooth, light blue dress (#8EC9F0), small yellow backpack (#F6C343).',
    personality: 'Curious and easily excited, loves colourful things, claps '
        'when she sees a combo.',
    palette: {'bows': '#E53935', 'dress': '#8EC9F0', 'backpack': '#F6C343'},
    pose: 'bouncy stance holding both backpack straps',
    props: ['red bow alone', 'backpack'],
    talk: 'one hand pointing up excitedly, eyes sparkling',
    happy: [
      'crouch, eyes wide with sparkles.',
      'big jump, both arms straight up, pigtails flying, gap-tooth grin.',
      'top of the jump, small yellow stars around.',
      'landed, hands on cheeks, delighted.',
    ],
    sad: [
      'smile fading, big eyes glistening.',
      'pouting with puffed cheeks.',
      'big teary eyes, lower lip trembling, hugging a backpack strap.',
      'same pose, looking down, pigtails drooping.',
    ],
    gait: 'happy skipping steps, pigtails and backpack bouncing.',
    signature: Anim('clap', 'when the player makes a combo', 'loop at 10 fps',
        'Excited clapping, front three-quarter view', [
      'hands apart, eyes sparkling.',
      'hands clap together, small impact lines.',
      'hands apart again, bouncing on tiptoes.',
      'clap again, mouth open shouting "wow".',
    ]),
  ),
  Character(
    file: '03-lucky-cat',
    en: 'Lucky Cat',
    th: 'แมวนำโชค',
    role: 'General customer `cust3` (any restaurant)',
    looks: 'a chubby maneki-neko lucky cat. White fur (#FFFFFF) with orange '
        'patches (#F28C38), narrow charming curved eyes, pink inner ears, a '
        'red collar (#D7262E) with a small bell and a gold koban coin '
        '(#F2C230) hanging from it, a short curled tail.',
    personality: 'Mysterious and playful, says little, likes to sneak fish.',
    palette: {'patches': '#F28C38', 'collar': '#D7262E', 'coin': '#F2C230'},
    pose: 'sitting upright with the left paw raised in the beckoning pose',
    props: ['gold koban coin alone', 'tail'],
    talk: 'raised paw beckoning down and up',
    happy: [
      'eyes shut in ^^ arcs, cheeks rosy.',
      'small hop, tosses the gold coin into the air with a sparkle.',
      'top of the hop, coin spinning above the head.',
      'landed, catches the coin, sly wink.',
    ],
    sad: [
      'raised paw lowering.',
      'ears flatten to the sides.',
      'tail droops, whiskers droop, small frown.',
      'curled up sitting, looking down.',
    ],
    gait: 'walking on all four paws, tail swishing, coin swinging.',
    walk: [
      'front-left and back-right paws forward.',
      'passing, body slightly higher.',
      'front-right and back-left paws forward.',
      'passing, body slightly higher.',
    ],
    signature: Anim('beckon', 'idle variation and level start', 'loop at 6 fps',
        'Classic maneki-neko beckoning, front view', [
      'left paw raised high, palm forward.',
      'paw curls down halfway.',
      'paw fully curled down.',
      'paw rising back, a tiny gold sparkle near the coin.',
    ]),
  ),
  Character(
    file: '04-yuki',
    en: 'Yuki',
    th: 'ยูกิ',
    role: 'General customer `cust4` (any restaurant)',
    looks: 'a fashionable Japanese teenager. Short pastel-blue hair '
        '(#9FD3F0), white headphones around the neck, an oversized lilac '
        'streetwear hoodie (#B9A3E3), baggy pants, chunky sneakers, a '
        'smartphone in one hand.',
    personality: 'Trendy, loves posting on social media; acts cool but is '
        'soft-hearted.',
    palette: {'hair': '#9FD3F0', 'hoodie': '#B9A3E3'},
    pose: 'one hand in the hoodie pocket, the other holding the phone',
    props: ['smartphone', 'headphones alone'],
    talk: 'phone hand gesturing casually',
    happy: [
      'raises the phone for a selfie.',
      'small hop, peace sign, wink.',
      'phone flash sparkle.',
      'landed, grinning at the phone screen.',
    ],
    sad: [
      'cool expression slipping.',
      'looks away with a pout.',
      'arms crossed, cheeks slightly puffed.',
      'same pose, glancing sideways, tiny blush.',
    ],
    gait: 'casual cool stroll with a slight sway, eyes on the phone.',
    signature: Anim(
        'photo',
        'when the order is served',
        'play once at 8 fps',
        'Taking a photo of the food, front '
            'three-quarter view',
        [
          'raises the phone with both hands.',
          'frames the shot, one eye closed, tongue out a little.',
          'white flash sparkle from the phone.',
          'checks the photo on the screen, pleased smirk.',
        ]),
  ),
  Character(
    file: '05-grandpa-taro',
    en: 'Grandpa Taro',
    th: 'คุณตาทาโร่',
    role: 'General customer `cust5` (any restaurant)',
    looks: 'a stern elderly Japanese grandfather. White hair, a long white '
        'drooping moustache, bushy white eyebrows, one eye squinting, a dark '
        'green haori jacket (#2E5E3A) over a grey kimono, a wooden walking '
        'cane (#8B5A2B).',
    personality: 'Serious and quiet, a harsh critic; praise is rare but means '
        'a lot. Smiles only once, at 3 stars.',
    palette: {'haori': '#2E5E3A', 'cane': '#8B5A2B'},
    pose: 'both hands resting on the cane, stern expression',
    props: ['cane', 'moustache alone'],
    talk: 'one hand lifted from the cane, finger raised as if lecturing',
    happy: [
      'still stern, one eyebrow rising.',
      'slow approving nod.',
      'a single small smile under the moustache, one tiny sparkle.',
      'small smile kept, eyes still serious.',
    ],
    sad: [
      'frown deepens.',
      'slowly shakes the head.',
      'arms crossed, cane leaning on the arm.',
      'eyes closed, disappointed "hmph".',
    ],
    gait: 'slow measured steps leaning on the cane.',
    signature: Anim('nod', 'when a goal is completed', 'play once at 6 fps',
        'Thoughtful "hmm" nod, front three-quarter view', [
      'strokes the moustache with one hand.',
      'eyes closed, considering.',
      'slow nod down.',
      'head back up, one eye opening, faint approval.',
    ]),
  ),

  // Tsukiji regulars.
  Character(
    file: '06-ryo',
    en: 'Ryo the Porter',
    th: 'ลุงเรียว',
    role: 'Tsukiji regular',
    looks: 'a burly fish-market porter. Tanned skin (#C98B5B), muscular arms, '
        'a white hachimaki headband, white tank top, dark blue work pants '
        '(#2B3F66), yellow rubber boots (#F2B630).',
    personality: 'Blunt, loud and generous, tired from hauling fish all '
        'morning.',
    palette: {'skin': '#C98B5B', 'pants': '#2B3F66', 'boots': '#F2B630'},
    pose: 'hands on hips, broad grin',
    props: ['headband alone', 'wooden fish crate'],
    talk: 'one hand cupped beside the mouth, shouting',
    happy: [
      'big grin, fists up.',
      'small hop, flexing one arm.',
      'top of the hop, laughing loudly, mouth wide.',
      'landed, thumbs up, sweat sparkle.',
    ],
    sad: [
      'grin fading.',
      'hand on a rumbling stomach, small "grr" lines.',
      'slumps forward, tired.',
      'sits down on the ground, sighing.',
    ],
    gait: 'heavy stomping strides, arms swinging.',
    signature: Anim('carry', 'level start', 'play once at 8 fps',
        'Hoisting a wooden fish crate, front three-quarter view', [
      'bends down, grabbing a wooden fish crate.',
      'lifts the crate to chest height, straining.',
      'swings the crate onto one shoulder.',
      'wipes sweat with the free hand, proud grin.',
    ]),
  ),
  Character(
    file: '07-auntie-kiku',
    en: 'Auntie Kiku',
    th: 'ป้าคิคุ',
    role: 'Tsukiji regular',
    looks: 'a middle-aged fish vendor. Curled hair under an orange headscarf '
        '(#E57A3C), a dark green rubber apron (#3E6B4F) over a striped shirt, '
        'rubber gloves, holding a small silver fish.',
    personality: 'Sharp-tongued haggler who knows fish better than anyone.',
    palette: {'headscarf': '#E57A3C', 'apron': '#3E6B4F'},
    pose: 'one hand on the hip, the other holding a small fish',
    props: ['small silver fish', 'headscarf alone'],
    talk: 'wagging the fish while making a point',
    happy: [
      'satisfied nod.',
      'small hop, laughing, waving the fish.',
      'hand on the hip, big laugh.',
      'landed, wink, fish held up proudly.',
    ],
    sad: [
      'eyebrow raised suspiciously.',
      'squinting.',
      'arms crossed, scowling.',
      'tapping a foot, unimpressed.',
    ],
    gait: 'confident waddle, swinging the fish.',
    signature: Anim(
        'inspect',
        'when the order bubble appears',
        'play once at 8 fps',
        'Inspecting a fish for freshness, front '
            'three-quarter view',
        [
          'lifts the fish up to the face.',
          'sniffs it, eyes closed.',
          'squints closely at it.',
          'approving nod, eyes open, small smile.',
        ]),
  ),
  Character(
    file: '08-masa',
    en: 'Masa the Auctioneer',
    th: 'คุณมาซะ',
    role: 'Tsukiji boss (level 15)',
    looks: 'a middle-aged fish auctioneer with an over-the-top manner. Red '
        'auction cap (#D33A2C) with a numbered badge, navy happi coat '
        '(#23395B), a brass hand bell (#D4A437), a towel around the neck.',
    personality: 'Talks fast like a salesman, loves racing the clock.',
    palette: {'cap': '#D33A2C', 'coat': '#23395B', 'bell': '#D4A437'},
    pose: 'holding the hand bell up, confident',
    props: ['hand bell', 'auction cap alone'],
    talk: 'pointing forward dramatically',
    happy: [
      'grin, bell raised.',
      'jump, ringing the bell with motion lines.',
      'top of the jump, small confetti.',
      'landed, triumphant pose.',
    ],
    sad: [
      'bell lowering.',
      'sweat drops, wavy mouth.',
      'bell drooping, shoulders down.',
      'cap tipped over the eyes.',
    ],
    gait: 'hurried bustling steps, bell in hand.',
    signature: Anim(
        'auction',
        'boss intro and timer warnings',
        'play once at 10 fps',
        'Auction call, front three-quarter view, '
            'dramatic boss energy',
        [
          'raises the bell high.',
          'rings it hard, motion lines.',
          'points forward, mouth wide shouting.',
          'slams a fist down: "Sold!", small impact star.',
        ]),
  ),

  // Osaka regulars.
  Character(
    file: '09-taco-neesan',
    en: 'Taco-neesan',
    th: 'เจ้ทาโกะ',
    role: 'Osaka regular',
    looks: 'a cheerful young takoyaki stall woman. Tall high orange ponytail '
        '(#F07A2A), chopsticks tucked behind one ear, red happi jacket '
        '(#D93A3A), a white towel with blue stripes over the shoulder, '
        'holding a takoyaki pick.',
    personality: 'Playful, Kansai accent, loves teasing customers.',
    palette: {'hair': '#F07A2A', 'happi': '#D93A3A'},
    pose: 'hand on the hip, holding a takoyaki pick',
    props: ['takoyaki pick', 'takoyaki ball', 'towel alone'],
    talk: 'pointing the pick forward teasingly',
    happy: [
      'laughing, hand over the mouth.',
      'small hop, teasing wink.',
      'peace sign, ponytail swinging.',
      'landed, big laugh.',
    ],
    sad: [
      'pout.',
      'puffed cheeks.',
      'stomps one foot, "mou!".',
      'arms crossed, looking away.',
    ],
    gait: 'lively bouncy stride, ponytail swinging.',
    signature: Anim('flip', 'idle variation', 'loop at 10 fps',
        'Flipping takoyaki, front three-quarter view', [
      'pick poised.',
      'flicks the pick.',
      'a takoyaki ball flipping in the air.',
      'catches it on the pick, wink.',
    ]),
  ),
  Character(
    file: '10-oto',
    en: 'Oto the Drummer',
    th: 'ตาโอโตะ',
    role: 'Osaka boss (level 30)',
    looks: 'an energetic teen taiko drummer. Blue wave-pattern headband '
        '(#2C6FB7), white happi with red trim (#C8332B), cloth wrist wraps, '
        'two wooden bachi drumsticks.',
    personality: 'Cheerful, loud and fast; always tapping a beat.',
    palette: {'headband': '#2C6FB7', 'trim': '#C8332B'},
    pose: 'drumsticks crossed in front of the chest',
    props: ['drumstick', 'small taiko drum'],
    talk: 'tapping a drumstick in the air to a beat',
    happy: [
      'big grin.',
      'jump, both sticks up.',
      'twirls the sticks, music notes.',
      'landed, victory pose.',
    ],
    sad: [
      'sticks lowering.',
      'slumped.',
      'sticks drooping at the sides.',
      'sitting, head down.',
    ],
    gait: 'rhythmic marching steps tapping sticks.',
    signature: Anim('drum', 'boss intro and combos', 'loop at 10 fps',
        'Drumming on a small taiko, front three-quarter view, boss energy', [
      'raises the right stick.',
      'hits the drum, impact lines.',
      'raises the left stick.',
      'hits the drum, music notes.',
    ]),
  ),
  Character(
    file: '11-aunt-hana',
    en: 'Aunt Hana',
    th: 'คุณป้าฮานะ',
    role: 'Osaka regular',
    looks: 'a chatty middle-aged side-dish seller. Curly purple hair '
        '(#8E5CC2), leopard-print top (#E3A63B), pearl necklace, a big red '
        'handbag (#C0392B).',
    personality: 'Squeals easily, loves gossip and freebies.',
    palette: {'hair': '#8E5CC2', 'top': '#E3A63B', 'handbag': '#C0392B'},
    pose: 'clutching the big handbag in both hands',
    props: ['handbag', 'handkerchief'],
    talk: 'one hand flapping in a gossiping gesture',
    happy: [
      'squeal.',
      'small hop, hands on the cheeks.',
      'hearts floating up.',
      'landed, waving.',
    ],
    sad: [
      'gasp.',
      'hand on the chest, dramatic.',
      'dabbing the eyes with a handkerchief.',
      'swoon pose.',
    ],
    gait: 'brisk waddle, handbag swinging.',
    signature: Anim(
        'bargain',
        'when the order bubble appears',
        'play once at 8 fps',
        'Begging for a freebie, front three-quarter '
            'view',
        [
          'hands pressed together.',
          'sparkly pleading eyes.',
          'winks.',
          'pinches a finger and thumb: "just a little".',
        ]),
  ),

  // Kyoto regulars.
  Character(
    file: '12-ume',
    en: 'Ume-san',
    th: 'คุณอุเมะ',
    role: 'Kyoto boss (level 45)',
    looks: 'a senior geisha. White face makeup, red lips, black hair in a '
        'traditional updo with plum-blossom hairpins, a plum-coloured kimono '
        '(#6B2C4A), gold obi (#D4A437), a golden folding fan.',
    personality: 'Elegant and calm; her critiques are soft but cut deep.',
    palette: {'kimono': '#6B2C4A', 'obi': '#D4A437'},
    pose: 'elegant posture, holding a closed golden fan',
    props: ['golden fan open', 'golden fan closed', 'plum hairpin alone'],
    talk: 'fan gesturing gracefully',
    happy: [
      'gentle smile.',
      'opens the fan.',
      'smiles behind the fan, eyes curved.',
      'slight gracious nod.',
    ],
    sad: [
      'smile fades.',
      'closes the fan with a snap.',
      'turns the head away.',
      'eyes closed, cool expression.',
    ],
    gait: 'tiny graceful steps.',
    signature: Anim('fan', 'boss intro', 'play once at 8 fps',
        'Elegant fan reveal, front three-quarter view, boss presence', [
      'fan closed.',
      'opens the fan halfway.',
      'fan fully open, hiding the mouth.',
      'peeks over the fan with a knowing look.',
    ]),
  ),
  Character(
    file: '13-haru',
    en: 'Haru',
    th: 'ฮารุ',
    role: 'Kyoto regular',
    looks: 'a shy tea-ceremony student. Lime-green kimono (#B5D96B) with a '
        'cream obi (#F2E6C8), dark hair in a low ponytail, holding a tea bowl '
        'with both hands.',
    personality: 'Polite, shy and attentive to detail.',
    palette: {'kimono': '#B5D96B', 'obi': '#F2E6C8'},
    pose: 'holding the tea bowl in both hands, shy',
    props: ['tea bowl'],
    talk: 'small bow while speaking',
    happy: [
      'blush.',
      'small happy hop.',
      'shy smile, eyes closed.',
      'landed, small bow.',
    ],
    sad: [
      'looks down.',
      'eyes watery.',
      'hides the face behind the tea bowl.',
      'peeks out sadly.',
    ],
    gait: 'tidy small steps.',
    signature: Anim('tea', 'level start', 'play once at 6 fps',
        'Offering tea, front three-quarter view', [
      'holds the bowl.',
      'turns the bowl.',
      'presents the bowl forward with a bow.',
      'shy smile.',
    ]),
  ),
  Character(
    file: '14-monk-genjo',
    en: 'Monk Genjo',
    th: 'หลวงพี่เก็นโจ',
    role: 'Kyoto regular',
    looks: 'a calm bald Japanese Buddhist monk. Deep orange robe (#D96B1F), '
        'dark brown prayer beads (#6B3E26), eyes closed in a serene smile.',
    personality: 'Peaceful; likes metaphors about a single grain of rice.',
    palette: {'robe': '#D96B1F', 'beads': '#6B3E26'},
    pose: 'palms pressed together, prayer beads hanging',
    props: ['prayer beads', 'single grain of rice'],
    blink: 'eyebrows lifting gently, serene',
    talk: 'one palm raised in a teaching gesture',
    happy: [
      'serene smile.',
      'small glowing aura.',
      'hands together, eyes closed.',
      'gentle nod.',
    ],
    sad: [
      'gentle sigh.',
      'head bowed.',
      'beads in both hands.',
      'calm acceptance, eyes closed.',
    ],
    gait: 'calm slow steps.',
    signature: Anim('meditate', 'idle variation', 'loop at 4 fps',
        'Meditating, front view', [
      'hands together, eyes closed.',
      'one grain of rice floats up.',
      'small glow around the grain.',
      'the grain settles, peaceful smile.',
    ]),
  ),

  // Hokkaido regulars.
  Character(
    file: '15-captain-umi',
    en: 'Captain Umi',
    th: 'กัปตันอุมิ',
    role: 'Hokkaido regular',
    looks: 'a burly fisherman. Fluffy grey beard, white captain\'s hat '
        '(#F4F4F4), navy knit sweater (#24375A), thick arms, rubber boots.',
    personality: 'Rough but funny; always telling sea stories.',
    palette: {'hat': '#F4F4F4', 'sweater': '#24375A'},
    pose: 'arms crossed, chest out',
    props: ['captain hat alone', 'crab'],
    talk: 'arms spread telling a story',
    happy: [
      'hearty laugh.',
      'small hop.',
      'slaps the belly.',
      'landed, thumbs up.',
    ],
    sad: [
      'grumble.',
      'pulls the hat down over the eyes.',
      'arms crossed.',
      'sighs, beard drooping.',
    ],
    gait: 'rolling sailor gait.',
    signature: Anim('tale', 'when the order bubble appears',
        'play once at 8 fps', 'Fish-tale gesture, front three-quarter view', [
      'hands together.',
      'hands apart.',
      'hands wider.',
      'arms widest: "this big!", laughing.',
    ]),
  ),
  Character(
    file: '16-yukiko',
    en: 'Yukiko',
    th: 'ยูกิโกะ',
    role: 'Hokkaido regular',
    looks: 'a sporty young ski guide. White knit beanie with a pom-pom, red '
        'scarf (#D7262E), teal ski jacket (#2BA3A8), cheeks red from the '
        'cold, goggles on the beanie.',
    personality: 'Athletic, straightforward, loves adventure.',
    palette: {'scarf': '#D7262E', 'jacket': '#2BA3A8'},
    pose: 'hands on hips, energetic',
    props: ['goggles', 'beanie alone'],
    talk: 'fist pumping while talking',
    happy: [
      'grin.',
      'jump, fist up.',
      'scarf flying.',
      'landed, thumbs up.',
    ],
    sad: [
      'shiver.',
      'hugs herself.',
      'teeth chattering.',
      'breath puff.',
    ],
    gait: 'energetic stride, scarf trailing.',
    signature: Anim('stretch', 'level start', 'play once at 8 fps',
        'Warm-up stretch, front three-quarter view', [
      'arms up.',
      'leans left.',
      'leans right.',
      'fist pump: "let\'s go!".',
    ]),
  ),
  Character(
    file: '17-chef-kuma',
    en: 'Chef Kuma',
    th: 'เชฟคุมะ',
    role: 'Hokkaido boss (level 60)',
    looks: 'a chubby brown bear (#8B5A2B) wearing a tall white chef hat and '
        'white apron, small kind eyes, round belly.',
    personality: 'Feared food critic with a soft heart and a weakness for '
        'honey.',
    palette: {'fur': '#8B5A2B'},
    pose: 'arms crossed, stern critic',
    props: ['tasting spoon', 'honey pot', 'chef hat alone'],
    talk: 'wagging a tasting spoon',
    happy: [
      '"hmph" turning into a smile.',
      'small hop.',
      'hugs a honey pot, hearts.',
      'landed, content.',
    ],
    sad: [
      'grumpy.',
      'turns away.',
      'arms crossed, "hmph".',
      'sulking, hat drooping.',
    ],
    gait: 'heavy waddle, belly bouncing.',
    signature: Anim(
        'taste',
        'boss intro and when the order is served',
        'play once at 6 fps',
        'Tasting critique, front three-quarter view, '
            'boss presence',
        [
          'lifts a tasting spoon.',
          'tastes, eyes closed.',
          'ponders, one paw on the chin.',
          'small approving smile: "hmph, not bad".',
        ]),
  ),

  // Board obstacle: Cat in lib/core/game_engine.dart.
  Character(
    file: '18-boss-cat-joker',
    en: 'Joker the Boss Cat',
    th: 'แมวหัวโจก โจ๊กเกอร์',
    role: 'Board obstacle boss: leader of the thieving cats; fits one board '
        'cell, drawn over the pieces',
    looks: 'a big chubby black stray cat (#2B2B33). One torn ear, '
        'squarish yellow eyes (#F5D33B), a cross-shaped scar on the nose, a '
        'silver spiked collar (#C0C4CC), a fish bone held in the mouth.',
    personality: 'Cocky, sneaky leader of the stray cat gang; steals '
        'customers\' fish but is scared of loud noises and explosions. '
        'Mischievous rather than scary, still kawaii.',
    palette: {'fur': '#2B2B33', 'eyes': '#F5D33B', 'collar': '#C0C4CC'},
    folder: 'obstacles',
    pose: 'sitting with a smug grin, fish bone in the mouth',
    props: ['fish bone', 'spiked collar alone'],
    anims: [
      Anim('idle', 'sitting on its cell', 'loop at 4 fps',
          'Smug idle loop, front three-quarter view', [
        'sitting, smug grin, fish bone in the mouth.',
        'tail swishes left.',
        'same as f1.',
        'eyes half closed, smug.',
      ]),
      Anim('prowl', 'moving to the next cell', 'loop at 8 fps',
          'Sneaky prowl, side view facing left, low to the ground', [
        'front-left and back-right paws forward.',
        'passing, body slightly higher, shoulders rolling.',
        'front-right and back-left paws forward.',
        'passing, sly sideways glance.',
      ]),
      Anim('eat', 'eats a neighbouring piece', 'play once at 10 fps',
          'Eating, front three-quarter view', [
        'leans forward, mouth open.',
        'chomps.',
        'chewing, cheeks full.',
        'licks the lips, satisfied.',
      ]),
      Anim(
          'hit',
          'loses HP',
          'play once at 12 fps',
          'Hissing in shock, front three-quarter view',
          [
            'startled, eyes wide.',
            'fur puffed up, jumps a little.',
            'hissing "fsst!", arched back.',
            'lands, glaring.',
          ],
          grounded: false),
      Anim(
          'flee',
          'HP reaches 0',
          'play once at 10 fps',
          'Fleeing, side view facing left',
          [
            'turns away, tail puffed.',
            'leaps forward.',
            'mid-run, legs stretched, dust puff.',
            'tail flick, dropping a gold coin behind.',
          ],
          grounded: false),
    ],
  ),
];
