const Map<String, Map<String, dynamic>> localizedDiseaseDatabase = {
  'en': {
    'Anthracnose': {
      'common_name': 'Anthracnose',
      'scientific_name': 'Colletotrichum gloeosporioides',
      'severity': 'high',
      'description': 'A widespread fungal disease affecting cashew leaves, flowers, and developing nuts. Severe during rainy seasons; spores spread rapidly via wind and rain splash.',
      'symptoms': [
        'Dark brown/black spots on leaves',
        'Leaf tip drying and scorching',
        'Flower blight — inflorescence turns brown and drops',
        'Young nut drop before maturity',
        'Dieback of shoots in severe cases',
      ],
      'treatments': [
        {
          'name': 'Field Sanitation',
          'type': 'mechanical',
          'description': 'Remove infected leaves, flowers, and fallen debris. Prune infected branches and burn or bury all infected material. Reduces fungal spore load significantly.',
          'timing': 'Immediately upon detecting symptoms',
        },
        {
          'name': 'Copper Oxychloride (0.3%)',
          'type': 'chemical',
          'description': 'Apply as preventive and curative spray on canopy. Highly effective at suppressing Colletotrichum.',
          'timing': 'Before flowering, at flowering, after fruit set. Repeat every 15–20 days during heavy rain.',
        },
        {
          'name': 'Bordeaux Mixture (1%)',
          'type': 'chemical',
          'description': 'A classic copper-lime based fungicide. Good protectant activity and helps prevent spread.',
          'timing': 'Before and during rainy season',
        },
        {
          'name': 'Carbendazim / Propiconazole / Mancozeb',
          'type': 'chemical',
          'description': 'Systemic fungicides (Carbendazim, Propiconazole) for curative effect. Mancozeb as a contact protectant. Rotate between different chemical groups to prevent resistance.',
          'timing': 'Second and third spray in season',
          'note': 'Rotate fungicides to prevent resistance build-up.',
        },
        {
          'name': 'Trichoderma-based Biofungicide',
          'type': 'biological',
          'description': 'Apply Trichoderma viride or T. harzianum as soil drench or foliar spray for eco-friendly suppression.',
          'timing': 'Before rainy season as a preventive measure',
        },
        {
          'name': 'Neem Oil Spray (2%)',
          'type': 'organic',
          'description': 'Mild preventive spray. Best used as an early-stage or low-pressure treatment.',
          'timing': 'Early signs / supplementary use',
        },
      ],
      'prevention': [
        {
          'measure': 'Improve Air Circulation',
          'description': 'Prune overcrowded canopy. Maintain proper spacing between trees to reduce leaf wetness duration.',
          'frequency': 'Annually after harvest',
        },
        {
          'measure': 'Balanced Nutrition',
          'description': 'Avoid excessive nitrogen fertilizer — too much soft growth is more susceptible to infection. Apply proper NPK with micronutrients.',
          'frequency': 'At each fertilization cycle',
        },
        {
          'measure': 'Preventive Sprays Before Rainy Season',
          'description': 'In humid climates with heavy monsoon rains, begin preventive copper sprays before the rains arrive.',
          'frequency': 'Before each monsoon onset',
        },
      ],
      'note': 'For research: Record disease severity index (0–5 scale) per tree along with rainfall data, tree age, canopy density, and fungicide history. This data can reveal disease-severity vs nut quality correlation and help identify disease-resistant trees.',
    },
    'Red_Rust': {
      'common_name': 'Red Rust (Algal Leaf Spot)',
      'scientific_name': 'Cephaleuros virescens',
      'severity': 'medium',
      'description': 'Caused by an algal pathogen (not a fungus). Orange-red velvety patches appear on older leaves and stems. Thrives in humid, shaded orchards with poor drainage. Common during Sri Lankan monsoon season.',
      'symptoms': [
        'Orange-red to rust-coloured velvety circular patches on leaves',
        'Patches mostly appear on older leaves and on the upper surface',
        'Can also affect bark/stems of young branches',
        'Common in humid, dense, and poorly-drained orchards',
      ],
      'treatments': [
        {
          'name': 'Copper Oxychloride (0.3%)',
          'type': 'chemical',
          'description': 'Most effective treatment for algal leaf spot. Spray directly on affected leaves and branches.',
          'timing': '2–3 sprays during early rainy season',
        },
        {
          'name': 'Bordeaux Mixture (1%)',
          'type': 'chemical',
          'description': 'Copper-lime based spray. Effective as a preventive coat against algal spread.',
          'timing': 'Before rainy season, repeat at 3-week intervals',
        },
      ],
      'prevention': [
        {
          'measure': 'Pruning & Sunlight Management',
          'description': 'Thin dense canopy to improve sunlight penetration. Red rust thrives in humid and shaded conditions. Remove crossing branches.',
          'frequency': 'Annually, after harvest',
        },
        {
          'measure': 'Improve Drainage',
          'description': 'Ensure good soil drainage in the orchard. Avoid waterlogging at tree base.',
        },
        {
          'measure': 'Balanced Nutrition',
          'description': 'Apply proper NPK fertilizers. Include micronutrients especially Zinc and Magnesium. Healthy, well-nourished trees resist algal infection better.',
          'frequency': 'Each fertilization cycle',
        },
        {
          'measure': 'Preventive Spraying',
          'description': 'In high-humidity climates, begin copper spray programme before the rainy season.',
          'frequency': 'Before every monsoon',
        },
      ],
      'note': 'Red rust is caused by algae, not fungi — so conventional fungicides are less effective. Copper-based products are the most reliable control option.',
    },
    'Leaf_Miner': {
      'common_name': 'Leaf Miner',
      'scientific_name': 'Acrocercops syngramma',
      'severity': 'low',
      'description': 'A minor pest primarily affecting young cashew leaves. Tiny caterpillars tunnel between the upper and lower surfaces of tender leaves, forming distinctive silvery blisters or serpentine trails.',
      'symptoms': [
        'Silvery or whitish blisters / mines on the upper surface of young leaves',
        'Serpentine (winding) trails visible through leaf surface',
        'Leaves may curl, distort, and dry up in severe cases',
        'Mostly affects the first flush of new leaves',
      ],
      'treatments': [
        {
          'name': 'Natural Enemy Conservation',
          'type': 'biological',
          'description': 'Parasitic wasps (chalcid parasitoids) naturally feed on leaf miner larvae. Avoid broad-spectrum pesticides that kill these beneficial insects.',
          'timing': 'Ongoing — encourage year-round',
        },
        {
          'name': 'Neem Oil Spray (2%)',
          'type': 'organic',
          'description': 'Spray 2% neem oil (with soft soap as emulsifier) during flushing to deter egg-laying females.',
          'timing': 'At first sign of new flushing',
        },
        {
          'name': 'Dimethoate (30 EC)',
          'type': 'chemical',
          'description': 'Spray Dimethoate 30 EC at 1.5 ml/litre only if the infestation exceeds the Economic Threshold Level. Avoid routine use to protect natural enemies.',
          'timing': 'New flush period',
          'note': 'Use only when infestation is severe; rotate with other chemistries.',
        },
      ],
      'prevention': [
        {
          'measure': 'Monitor New Flushes',
          'description': 'Inspect flushing regularly to detect early leaf miner activity before populations build up.',
          'frequency': 'Weekly during flush periods',
        },
        {
          'measure': 'Avoid Over-fertilising with Nitrogen',
          'description': 'Excess nitrogen promotes rapid, soft flushes that are more attractive to leaf miner egg-laying. Use balanced NPK.',
        },
      ],
      'note': 'Leaf miner is generally a minor pest and rarely causes significant economic damage. Heavy-handed chemical use often kills natural parasitoids and worsens long-term infestations.',
    },
  },
  'si': {
    'Anthracnose': {
      'common_name': 'ඇන්ත්‍රැක්නෝස් (කොළ අංගමාරය)',
      'scientific_name': 'Colletotrichum gloeosporioides',
      'severity': 'high',
      'description': 'කජු කොළ, මල් සහ ළපටි ගෙඩි වලට බලපාන පුළුල් දිලීර රෝගයකි. වර්ෂා කාලයේදී දැඩි වේ; සුළඟ සහ වර්ෂාව මගින් බීජාණු වේගයෙන් පැතිරෙයි.',
      'symptoms': [
        'කොළ මත තද දුඹුරු/කළු ලප',
        'කොළ අග වේළීම සහ පිළිස්සීම',
        'මල් අංගමාරය - මල් දුඹුරු වී හැලී යාම',
        'මේරීමට පෙර ළපටි ගෙඩි හැලී යාම',
        'දරුණු අවස්ථාවලදී රිකිලි මැරී යාම',
      ],
      'treatments': [
        {
          'name': 'ක්ෂේත්‍ර සනීපාරක්ෂාව',
          'type': 'mechanical',
          'description': 'ආසාදිත කොළ, මල් සහ වැටුණු සුන්බුන් ඉවත් කරන්න. ආසාදිත අතු කපා පුළුස්සා හෝ වළදමන්න. මෙය දිලීර බීජාණු ප්‍රමාණය සැලකිය යුතු ලෙස අඩු කරයි.',
          'timing': 'රෝග ලක්ෂණ හඳුනාගත් විගස',
        },
        {
          'name': 'කොපර් ඔක්සික්ලෝරයිඩ් (0.3%)',
          'type': 'chemical',
          'description': 'නිවාරක සහ සුව කිරීමේ ඉසින ලෙස පත්‍ර මත යොදන්න. දිලීර මර්දනය සඳහා ඉතා ඵලදායී වේ.',
          'timing': 'මල් පිපීමට පෙර, මල් පිපෙන විට සහ ගෙඩි හටගත් පසු. තද වැසි කාලයේදී දින 15–20 වරක් නැවත යොදන්න.',
        },
        {
          'name': 'බෝඩෝ මිශ්‍රණය (1%)',
          'type': 'chemical',
          'description': 'සම්භාව්‍ය තඹ සහ හුණු පදනම් වූ දිලීර නාශකයකි. හොඳ ආරක්ෂාවක් ලබා දෙන අතර රෝගය පැතිරීම වළක්වයි.',
          'timing': 'වර්ෂා කාලයට පෙර සහ වර්ෂා කාලය තුළ',
        },
        {
          'name': 'කාබෙන්ඩසිම් / ප්‍රොපිකොනසෝල් / මැන්කොසෙබ්',
          'type': 'chemical',
          'description': 'සුව කිරීමේ බලපෑම සඳහා පද්ධතිමය දිලීර නාශක. ස්පර්ශක ආරක්ෂකයක් ලෙස මැන්කොසෙබ්.',
          'timing': 'කන්නයේ දෙවන සහ තෙවන ඉසීම',
          'note': 'ප්‍රතිරෝධය ඇතිවීම වැළැක්වීම සඳහා දිලීර නාශක මාරු කරමින් භාවිතා කරන්න.',
        },
        {
          'name': 'ට්‍රයිකොඩර්මා ජීව දිලීර නාශක',
          'type': 'biological',
          'description': 'ට්‍රයිකොඩර්මා (Trichoderma) පසට දියකර හෝ පත්‍ර මත ඉසීම මගින් පරිසර හිතකාමී ලෙස මර්දනය කළ හැක.',
          'timing': 'වැසි කාලයට පෙර ආරක්ෂිත පියවරක් ලෙස',
        },
        {
          'name': 'කොහොඹ තෙල් (2%)',
          'type': 'organic',
          'description': 'මෘදු නිවාරක ඉසිනයකි. මුල් අවධියේදී හෝ අඩු පීඩන තත්වයන් යටතේ වඩාත් සුදුසුය.',
          'timing': 'මුල් සංඥා දුටුවිට',
        },
      ],
      'prevention': [
        {
          'measure': 'වාතය සංසරණය වැඩි දියුණු කිරීම',
          'description': 'අධික ලෙස වැඩුණු අතු කපා ඉවත් කරන්න. ගස් අතර නිසි පරතරයක් පවත්වා ගන්න.',
          'frequency': 'වාර්ෂිකව අස්වැන්න නෙලීමෙන් පසු',
        },
        {
          'measure': 'සමතුලිත පෝෂණය',
          'description': 'අධික නයිට්‍රජන් පොහොර දීමෙන් වළකින්න. ක්ෂුද්‍ර පෝෂක සමඟ නිසි NPK යොදන්න.',
          'frequency': 'සෑම පොහොර යෙදීම් වාරයකදීම',
        },
        {
          'measure': 'වැසි කාලයට පෙර නිවාරක ඉසීම',
          'description': 'අධික මෝසම් වැසි සහිත තෙත් දේශගුණයන්හි, වැසි පැමිණීමට පෙර නිවාරක තඹ ඉසීම ආරම්භ කරන්න.',
          'frequency': 'සෑම මෝසම් කාලයකටම පෙර',
        },
      ],
      'note': 'අධ්‍යයන සඳහා: වර්ෂාපතන දත්ත, ගසේ වයස සහ දිලීර නාශක ඉතිහාසය සමඟ රෝග තීව්‍රතා දර්ශකය වාර්තා කරන්න.',
    },
    'Red_Rust': {
      'common_name': 'රතු මලකඩ (ඇල්ගී පත්‍ර ලපය)',
      'scientific_name': 'Cephaleuros virescens',
      'severity': 'medium',
      'description': 'ඇල්ගී රෝග කාරකයක් නිසා ඇතිවේ (දිලීරයක් නොවේ). පැරණි කොළ සහ කඳන් මත තැඹිලි-රතු පැහැති ලප ඇතිවේ. ජලවහනය දුර්වල සෙවන සහිත වගාවන්හි බහුලය.',
      'symptoms': [
        'කොළ මත තැඹිලි-රතු පැහැති රවුම් ලප',
        'ලප බොහෝ විට පැරණි කොළ සහ උඩ ස්තරය මත දිස්වේ',
        'ළපටි අතුවල පොත්තට/කඳට ද බලපෑම් කළ හැක',
        'අධික ආර්ද්‍රතාවය සහ දුර්වල ජලවහනය ඇති වගාවන්හි බහුලය',
      ],
      'treatments': [
        {
          'name': 'කොපර් ඔක්සික්ලෝරයිඩ් (0.3%)',
          'type': 'chemical',
          'description': 'ඇල්ගී පත්‍ර ලපය සඳහා වඩාත් ඵලදායී ප්‍රතිකාරය. බලපෑමට ලක්වූ කොළ සහ අතු මත කෙලින්ම ඉසින්න.',
          'timing': 'මුල් වර්ෂා කාලයේදී 2-3 වතාවක්',
        },
        {
          'name': 'බෝඩෝ මිශ්‍රණය (1%)',
          'type': 'chemical',
          'description': 'තඹ සහ හුණු පදනම් වූ ඉසිනයකි. ඇල්ගී පැතිරීමට එරෙහිව නිවාරකයක් ලෙස ඵලදායී වේ.',
          'timing': 'වර්ෂා කාලයට පෙර, සති 3 කට වරක් නැවත යොදන්න',
        },
      ],
      'prevention': [
        {
          'measure': 'කප්පාදු කිරීම සහ හිරු එළිය කළමනාකරණය',
          'description': 'හිරු එළිය හොඳින් වැටීම සඳහා ඝන අතු කපා ඉවත් කරන්න. රතු මලකඩ තෙත් සහ සෙවන සහිත තත්වයන් තුළ හොඳින් වර්ධනය වේ.',
          'frequency': 'වාර්ෂිකව, අස්වැන්න නෙලීමෙන් පසු',
        },
        {
          'measure': 'ජලවහනය වැඩි දියුණු කිරීම',
          'description': 'වගාවේ හොඳ පස් ජලවහනයක් සහතික කරන්න. ගස මුල ජලය රැඳීමෙන් වළකින්න.',
        },
        {
          'measure': 'සමතුලිත පෝෂණය',
          'description': 'නිසි NPK පොහොර යොදන්න. සින්ක් සහ මැග්නීසියම් ඇතුළු ක්ෂුද්‍ර පෝෂක එකතු කරන්න.',
          'frequency': 'සෑම පොහොර යෙදීම් වාරයකදීම',
        },
        {
          'measure': 'නිවාරක රසායනික ඉසීම',
          'description': 'අධික ආර්ද්‍රතා සහිත දේශගුණයන්හි, වැසි කාලයට පෙර තඹ ඉසීමේ වැඩසටහන ආරම්භ කරන්න.',
          'frequency': 'සෑම මෝසම් කාලයකටම පෙර',
        },
      ],
      'note': 'රතු මලකඩ ඇති වන්නේ ඇල්ගී මගිනි, දිලීර මගින් නොවේ - එබැවින් සාම්ප්‍රදායික දිලීර නාශක ඵලදායී බවින් අඩුය. තඹ පදනම් වූ නිෂ්පාදන වඩාත් විශ්වාසදායක පාලන විකල්පය වේ.',
    },
    'Leaf_Miner': {
      'common_name': 'පත්‍ර ඛනකයා (කොළ කන කුරුමිනියා)',
      'scientific_name': 'Acrocercops syngramma',
      'severity': 'low',
      'description': 'ළපටි කජු කොළ වලට ප්‍රධාන වශයෙන් බලපාන සුළු පළිබෝධකයෙකි. කුඩා දළඹුවන් ළපටි පත්‍රවල ඉහළ සහ පහළ පෘෂ්ඨ අතර උමං සාදයි, දීප්තිමත් රිදී පැහැති සලකුණු ඇති කරයි.',
      'symptoms': [
        'ළපටි කොළවල ඉහළ පෘෂ්ඨයේ රිදී හෝ සුදු පැහැති බිබිලි / උමං',
        'කොළ මතුපිටින් පෙනෙන සර්පාකාර (වංගු සහිත) ඉරි',
        'දරුණු අවස්ථාවලදී කොළ හැකිලීම, විකෘති වීම සහ වේළීම',
        'බොහෝ විට නව දළු වලට බලපායි',
      ],
      'treatments': [
        {
          'name': 'ස්වාභාවික සතුරන් සංරක්ෂණය',
          'type': 'biological',
          'description': 'පරපෝෂිත බඹරුන් ස්වාභාවිකවම පත්‍ර ඛනක කීටයන් ආහාරයට ගනිති. මෙම හිතකර කෘමීන් විනාශ කරන පුළුල් පරාසයක පළිබෝධනාශකවලින් වළකින්න.',
          'timing': 'නිරන්තරයෙන් - වසර පුරා දිරිමත් කරන්න',
        },
        {
          'name': 'කොහොඹ තෙල් (2%)',
          'type': 'organic',
          'description': 'ගැහැණු සතුන් බිත්තර දැමීම අධෛර්යමත් කිරීම සඳහා දළු ලියලන විට 2% කොහොඹ තෙල් ඉසින්න.',
          'timing': 'නව දළු දමන මුල් අවස්ථාවේදී',
        },
        {
          'name': 'ඩයිමෙතෝඒට් (30 EC)',
          'type': 'chemical',
          'description': 'ආසාදනය ආර්ථික හානිදායක මට්ටම ඉක්මවා ගියහොත් පමණක් ඩයිමෙතෝඒට් 30 EC ලීටරයකට මිලි ලීටර් 1.5 බැගින් ඉසින්න.',
          'timing': 'නව දළු දමන කාලය',
          'note': 'භාවිතා කළ යුත්තේ ආසාදනය දරුණු වූ විට පමණි; වෙනත් රසායනික ද්‍රව්‍ය සමඟ මාරු කරමින් භාවිතා කරන්න.',
        },
      ],
      'prevention': [
        {
          'measure': 'නව දළු නිරීක්ෂණය',
          'description': 'පත්‍ර ඛනක ගහනය වර්ධනය වීමට පෙර මුල් ක්‍රියාකාරකම් හඳුනා ගැනීම සඳහා දළු ක්‍රමානුකූලව පරීක්ෂා කරන්න.',
          'frequency': 'දළු දමන කාලවලදී සතිපතා',
        },
        {
          'measure': 'නයිට්‍රජන් අධික ලෙස යෙදීමෙන් වළකින්න',
          'description': 'අතිරික්ත නයිට්‍රජන් නිසා ශීඝ්‍ර, මෘදු දළු වර්ධනයක් ඇති කරන අතර එය පත්‍ර ඛනකයාට බිත්තර දැමීමට වඩාත් ආකර්ෂණීය වේ.',
        },
      ],
      'note': 'පත්‍ර ඛනකයා සාමාන්‍යයෙන් සුළු පළිබෝධකයෙකු වන අතර කලාතුරකින් සැලකිය යුතු ආර්ථික හානියක් සිදු කරයි. රසායනික ද්‍රව්‍ය අධික ලෙස භාවිතා කිරීම බොහෝ විට ස්වාභාවික පරපෝෂිතයින් විනාශ කරන අතර දිගුකාලීන ආසාදන වඩාත් නරක අතට හැරේ.',
    },
  },
  'ta': {
    'Anthracnose': {
      'common_name': 'ஆந்த்ராக்னோஸ் (இலை கருகல்)',
      'scientific_name': 'Colletotrichum gloeosporioides',
      'severity': 'high',
      'description': 'முந்திரி இலைகள், பூக்கள் மற்றும் வளரும் கொட்டைகளை பாதிக்கும் ஒரு பரவலான பூஞ்சை நோய். மழைக்காலத்தில் தீவிரமானது; காற்று மற்றும் மழை மூலம் வித்திகள் வேகமாக பரவுகின்றன.',
      'symptoms': [
        'இலைகளில் அடர் பழுப்பு/கருப்பு புள்ளிகள்',
        'இலையின் நுனி காய்ந்து கருகியிருத்தல்',
        'பூஞ்சைக் கருகல் - பூக்கள் பழுப்பு நிறமாக மாறி உதிர்தல்',
        'முதிர்வதற்கு முன் இளம்பருவ கொட்டைகள் உதிர்தல்',
        'கடுமையான சந்தர்ப்பங்களில் கிளைகள் காய்ந்து போதல்',
      ],
      'treatments': [
        {
          'name': 'வயல் சுகாதாரம்',
          'type': 'mechanical',
          'description': 'பாதிக்கப்பட்ட இலைகள், பூக்கள் மற்றும் விழுந்த குப்பைகளை அகற்றவும். பாதிக்கப்பட்ட கிளைகளை கத்தரித்து எரித்து அல்லது புதைக்கவும். இது பூஞ்சை வித்திகளின் சுமையை கணிசமாகக் குறைக்கிறது.',
          'timing': 'அறிகுறிகள் கண்டறிந்தவுடன் உடனடியாக',
        },
        {
          'name': 'காப்பர் ஆக்ஸிகுளோரைடு (0.3%)',
          'type': 'chemical',
          'description': 'தடுப்பு மற்றும் தீர்வு தெளிப்பாக இலைகளில் பயன்படுத்தவும். பூஞ்சையை கட்டுப்படுத்துவதில் மிகவும் பயனுள்ளதாக இருக்கும்.',
          'timing': 'பூப்பதற்கு முன், பூக்கும் போது, மற்றும் பழம் உருவான பிறகு. பலத்த மழையின் போது 15-20 நாட்களுக்கு ஒருமுறை மீண்டும் செய்யவும்.',
        },
        {
          'name': 'போர்டியாக்ஸ் கலவை (1%)',
          'type': 'chemical',
          'description': 'ஒரு உன்னதமான தாமிரம்-சுண்ணாம்பு அடிப்படையிலான பூஞ்சைக் கொல்லி. நல்ல பாதுகாப்பு செயல்பாடு மற்றும் பரவுவதைத் தடுக்க உதவுகிறது.',
          'timing': 'மழைக்காலத்திற்கு முன் மற்றும் மழைக்காலத்தின் போது',
        },
        {
          'name': 'கார்பென்டாசிம் / ப்ரோபிகோனசோல் / மாங்கோசெப்',
          'type': 'chemical',
          'description': 'குணப்படுத்தும் விளைவுக்கு முறையான பூஞ்சைக் கொல்லிகள். மாங்கோசெப் ஒரு தொடர்பு பாதுகாப்பாளராக. எதிர்ப்பு உருவாகாமல் தடுக்க ரசாயனங்களை மாற்றிக் கொண்டே இருக்கவும்.',
          'timing': 'பருவத்தில் இரண்டாவது மற்றும் மூன்றாவது தெளிப்பு',
          'note': 'எதிர்ப்பு உருவாகாமல் தடுக்க பூஞ்சைக் கொல்லிகளை மாற்றிக் கொண்டே இருக்கவும்.',
        },
        {
          'name': 'ட்ரைக்கோடெர்மா உயிரியல் பூஞ்சைக் கொல்லி',
          'type': 'biological',
          'description': 'சூழல் நட்பு கட்டுப்பாட்டிற்கு ட்ரைக்கோடெர்மாவை மண்ணில் அல்லது இலைகளில் தெளிக்கவும்.',
          'timing': 'மழைக்காலத்திற்கு முன் ஒரு தடுப்பு நடவடிக்கையாக',
        },
        {
          'name': 'வேப்ப எண்ணெய் தெளிப்பு (2%)',
          'type': 'organic',
          'description': 'லேசான தடுப்பு தெளிப்பு. ஆரம்ப நிலை அல்லது குறைந்த அழுத்த சிகிச்சைக்கு ஏற்றது.',
          'timing': 'ஆரம்ப அறிகுறிகள் தென்படும் போது',
        },
      ],
      'prevention': [
        {
          'measure': 'காற்றோட்டத்தை மேம்படுத்துதல்',
          'description': 'அதிகமாக வளர்ந்த கிளைகளை கத்தரிக்கவும். மரங்களுக்கு இடையே சரியான இடைவெளியை பராமரிக்கவும்.',
          'frequency': 'அறுவடைக்குப் பிறகு ஆண்டுதோறும்',
        },
        {
          'measure': 'சமச்சீர் ஊட்டச்சத்து',
          'description': 'அதிகப்படியான நைட்ரஜன் உரமிடுவதைத் தவிர்க்கவும். நுண் ஊட்டச்சத்துக்களுடன் சரியான NPK உரத்தைப் பயன்படுத்தவும்.',
          'frequency': 'ஒவ்வொரு உரமிடும் சுழற்சியிலும்',
        },
        {
          'measure': 'மழைக்காலத்திற்கு முன் தடுப்பு தெளிப்பு',
          'description': 'அதிக பருவமழை உள்ள ஈரப்பதமான காலநிலைகளில், மழை தொடங்குவதற்கு முன் தடுப்பு தாமிர தெளிப்புகளை தொடங்கவும்.',
          'frequency': 'ஒவ்வொரு பருவமழைக்கும் முன்பு',
        },
      ],
      'note': 'ஆராய்ச்சிக்கு: மரத்தின் நோய் தீவிர সূசீ (0-5 அளவு), மழைப்பொழிவு தரவு, மரத்தின் வயது மற்றும் பூஞ்சைக் கொல்லி வரலாற்றை பதிவு செய்யவும்.',
    },
    'Red_Rust': {
      'common_name': 'சிவப்பு துரு (பாசி இலைப்புள்ளி)',
      'scientific_name': 'Cephaleuros virescens',
      'severity': 'medium',
      'description': 'பாசி நோய்க்கிருமியால் ஏற்படுகிறது (பூஞ்சை அல்ல). பழைய இலைகள் மற்றும் தண்டுகளில் ஆரஞ்சு-சிவப்பு மென்மையான திட்டுகள் தோன்றும். ஈரப்பதமான, நிழலான மற்றும் மோசமான வடிகால் உள்ள இடங்களில் பரவுகிறது.',
      'symptoms': [
        'இலைகளில் ஆரஞ்சு-சிவப்பு முதல் துரு நிறத்திலான வட்ட வடிவ திட்டுகள்',
        'திட்டுகள் பெரும்பாலும் பழைய இலைகள் மற்றும் மேல் பரப்பில் தோன்றும்',
        'இளம் கிளைகளின் பட்டை/தண்டுகளையும் பாதிக்கலாம்',
        'ஈரப்பதமான, அடர்ந்த மற்றும் மோசமான வடிகால் உள்ள பழத்தோட்டங்களில் பொதுவானது',
      ],
      'treatments': [
        {
          'name': 'காப்பர் ஆக்ஸிகுளோரைடு (0.3%)',
          'type': 'chemical',
          'description': 'பாசி இலைப்புள்ளிக்கு மிகவும் பயனுள்ள சிகிச்சை. பாதிக்கப்பட்ட இலைகள் மற்றும் கிளைகளின் மீது நேரடியாகத் தெளிக்கவும்.',
          'timing': 'ஆரம்ப மழைக்காலத்தில் 2-3 முறை தெளிக்கவும்',
        },
        {
          'name': 'போர்டியாக்ஸ் கலவை (1%)',
          'type': 'chemical',
          'description': 'தாமிரம்-சுண்ணாம்பு அடிப்படையிலான தெளிப்பு. பாசி பரவுவதற்கு எதிரான தடுப்பு பூச்சாக செயல்படுகிறது.',
          'timing': 'மழைக்காலத்திற்கு முன், 3 வார இடைவெளியில் மீண்டும் செய்யவும்',
        },
      ],
      'prevention': [
        {
          'measure': 'கத்தரித்தல் மற்றும் சூரிய ஒளி மேலாண்மை',
          'description': 'சூரிய ஒளி நன்கு ஊடுருவ நெருக்கமான கிளைகளை கத்தரிக்கவும். சிவப்பு துரு ஈரப்பதமான மற்றும் நிழலான சூழ்நிலைகளில் செழித்து வளரும்.',
          'frequency': 'ஆண்டுதோறும், அறுவடைக்குப் பிறகு',
        },
        {
          'measure': 'வடிகால் வசதியை மேம்படுத்துதல்',
          'description': 'பழத்தோட்டத்தில் நல்ல மண் வடிகால் இருப்பதை உறுதி செய்யவும். மரத்தின் அடியில் தண்ணீர் தேங்குவதைத் தவிா்க்கவும்.',
        },
        {
          'measure': 'சமச்சீர் ஊட்டச்சத்து',
          'description': 'சரியான NPK உரங்களைப் பயன்படுத்தவும். துத்தநாகம் மற்றும் மெக்னீசியம் உள்ளிட்ட நுண் ஊட்டச்சத்துக்களைச் சேர்க்கவும்.',
          'frequency': 'ஒவ்வொரு உரமிடும் சுழற்சியிலும்',
        },
        {
          'measure': 'தடுப்பு ரசாயன தெளிப்பு',
          'description': 'அதிக ஈரப்பதமான காலநிலைகளில், மழைக்காலத்திற்கு முன் தாமிர தெளிப்பு திட்டத்தைத் தொடங்கவும்.',
          'frequency': 'ஒவ்வொரு பருவமழைக்கும் முன்பு',
        },
      ],
      'note': 'சிவப்பு துரு பாசியால் ஏற்படுகிறது, பூஞ்சைகளால் அல்ல - எனவே வழக்கமான பூஞ்சைக் கொல்லிகள் குறைந்த செயல்திறன் கொண்டவை. தாமிர அடிப்படையிலான தயாரிப்புகளே மிகவும் நம்பகமான கட்டுப்பாட்டு அம்சமாகும்.',
    },
    'Leaf_Miner': {
      'common_name': 'இலைத் துளைப்பான்',
      'scientific_name': 'Acrocercops syngramma',
      'severity': 'low',
      'description': 'முக்கியமாக இளம் முந்திரி இலைகளைப் பாதிக்கும் ஒரு சிறிய பூச்சி. சிறிய கம்பளிப்பூச்சிகள் இலைகளின் மேல் மற்றும் கீழ் பரப்புகளுக்கு இடையே சுரங்கங்களைத் தோண்டி, வெள்ளி நிற கொப்புளங்கள் அல்லது பாம்பு போன்ற தடங்களை உருவாக்குகின்றன.',
      'symptoms': [
        'இளம் இலைகளின் மேல் பரப்பில் வெள்ளி அல்லது வெள்ளை நிற கொப்புளங்கள் / சுரங்கங்கள்',
        'இலையின் மேற்பரப்பில் வளைந்து நெளிந்து செல்லும் (பாம்பு போன்ற) தடங்கள்',
        'கடுமையான சந்தர்ப்பங்களில் இலைகள் சுருண்டு, சிதைந்து காய்ந்து போகலாம்',
        'புதிய இலைகளையே அதிகம் பாதிக்கிறது',
      ],
      'treatments': [
        {
          'name': 'இயற்கை எதிரி பாதுகாப்பு',
          'type': 'biological',
          'description': 'ஒட்டுண்ணி குளவிகள் இயற்கையாகவே இலைத் துளைப்பான் லார்வாக்களை உண்ணும். இந்த நன்மை பயக்கும் பூச்சிகளைக் கொல்லும் பரந்த-ஸ்பெக்ட்ரம் பூச்சிக்கொல்லிகளைத் தவிர்க்கவும்.',
          'timing': 'தொடர்ந்து - ஆண்டு முழுவதும் ஊக்குவிக்கவும்',
        },
        {
          'name': 'வேப்ப எண்ணெய் தெளிப்பு (2%)',
          'type': 'organic',
          'description': 'பெண் பூச்சிகள் முட்டையிடுவதைத் தடுக்க புதிய இலைகள் வளரும் போது 2% வேப்ப எண்ணெய் தெளிக்கவும்.',
          'timing': 'புதிய இலைகள் வளரும் ஆரம்ப நிலையில்',
        },
        {
          'name': 'டைமெத்தோயேட் (30 EC)',
          'type': 'chemical',
          'description': 'பூச்சி தாக்குதல் பொருளாதார வரம்பை தாண்டினால் மட்டுமே லிட்டருக்கு 1.5 மில்லி வீதம் டைமெத்தோயேட் 30 EC ஐ தெளிக்கவும்.',
          'timing': 'புதிய இலைகள் தளிர் விடும் காலம்',
          'note': 'தாக்குதல் கடுமையாக இருக்கும் போது மட்டுமே பயன்படுத்தவும்; ரசாயனங்களை மாற்றிக் கொண்டே இருக்கவும்.',
        },
      ],
      'prevention': [
        {
          'measure': 'புதிய தளிர்களைக் கண்காணித்தல்',
          'description': 'இலைத் துளைப்பான் எண்ணிக்கை பெருகுவதற்கு முன், ஆரம்பகால செயல்பாட்டைக் கண்டறிய தளிர்களைத் தொடர்ந்து பரிசோதிக்கவும்.',
          'frequency': 'தளிர் விடும் காலங்களில் வாரந்தோறும்',
        },
        {
          'measure': 'அதிகப்படியான நைட்ரஜன் உரமிடுவதைத் தவிர்க்கவும்',
          'description': 'அதிகப்படியான நைட்ரஜன் விரைவான, மென்மையான தளிர்களை ஊக்குவிக்கிறது, இது இலைத் துளைப்பான்கள் முட்டையிட மிகவும் ஈர்க்கிறது.',
        },
      ],
      'note': 'இலைத் துளைப்பான் பொதுவாக ஒரு சிறிய பூச்சியாகும், மேலும் அரிதாகவே குறிப்பிடத்தக்க பொருளாதார சேதத்தை உருவாக்குகிறது. ரசாயனங்களை அதிகமாகப் பயன்படுத்துவது பெரும்பாலும் இயற்கை ஒட்டுண்ணிகளைக் கொன்று, நீண்ட கால தாக்குதலை மோசமாக்கும்.',
    },
  },
};
