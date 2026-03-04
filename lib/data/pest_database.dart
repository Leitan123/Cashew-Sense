const Map<String, Map<String, dynamic>> localizedPestDatabase = {
  'en': {
    'Thrips': {
      'scientific_name': 'Scirtothrips dorsalis',
      'severity': 'medium',
      'description': 'Minute insects that scrape and suck sap from leaves and floral parts, leading to stunted shoots and scarred nuts.',
      'symptoms': [
        'Scab marks on the surface of cashew nuts',
        'Corky, brownish discoloration on apples',
        'Leaves becoming pale and curled'
      ],
      'treatments': [
        {
          'name': 'Neem formulation',
          'type': 'organic',
          'eco_friendly': true,
          'description': 'Spray NSKE (Neem Seed Kernel Extract) 5% during flowering.',
          'timing': 'Flowering/Fruiting stage'
        },
        {
          'name': 'Profenofos',
          'type': 'chemical',
          'eco_friendly': false,
          'description': 'Spray Profenofos 50 EC (1 ml/litre) if severe.',
          'timing': 'When scabs become highly visible'
        }
      ],
      'prevention': [
        {
           'measure': 'Monitor Flushing',
           'description': 'Frequent scouting of flushing to catch the population build-up early.'
        }
      ]
    },
    'mites': {
      'scientific_name': 'Tetranychidae',
      'severity': 'medium',
      'description': 'Spider mites that feed on plant sap, commonly found on the underside of cashew leaves causing speckling and webbing.',
      'symptoms': [
        'Tiny yellowish or white speckles on leaves',
        'Fine webbing on the underside of leaves',
        'Bronze or silvery appearance of damaged leaves',
        'Leaf dropping in severe cases'
      ],
      'treatments': [
         {
          'name': 'Predatory Mites',
          'type': 'biological',
          'eco_friendly': true,
          'description': 'Release Phytoseiulus persimilis or other predatory mites.',
          'timing': 'Early signs of damage'
        },
        {
          'name': 'Wettable Sulphur',
          'type': 'chemical',
          'eco_friendly': false,
          'description': 'Spray wettable sulphur (3g/litre).',
          'timing': 'During dry spells when mite populations peak',
          'frequency': 'Every 10-15 days'
        }
      ],
      'prevention': [
         {
           'measure': 'Adequate Irrigation',
           'description': 'Water stress combined with warm weather encourages mite outbreaks.'
         }
      ]
    },
    'stem_borer': {
      'scientific_name': 'Plocaederus ferrugineus',
      'severity': 'high',
      'description': 'A lethal pest causing the death of the entire cashew tree. The grubs bore into the bark and sapwood of the main stem and roots.',
      'symptoms': [
        'Yellowing of leaves followed by drying of twigs',
        'Presence of small holes in the collar region',
        'Extrusion of frass (powdery material) mixed with gum',
        'Yellowing and shedding of leaves leading to death'
      ],
      'treatments': [
        {
          'name': 'Mechanical Extraction',
          'type': 'mechanical',
          'eco_friendly': true,
          'description': 'Chisel out the bark of the tunneled portion and mechanically kill the grub.',
          'timing': 'Early stages of infestation'
        },
        {
          'name': 'Chlorpyriphos Swabbing',
          'type': 'chemical',
          'eco_friendly': false,
          'description': 'Swab the main stem up to 1 meter height and exposed roots with Chlorpyriphos 20 EC (10ml/litre).',
          'timing': 'After mechanical extraction',
          'frequency': 'Once/Twice a year'
        }
      ],
      'prevention': [
        {
          'measure': 'Phyto-sanitation',
          'description': 'Remove and burn dead and severely infested trees to prevent the spread to adjacent trees.',
          'frequency': 'Immediate'
        }
      ],
      'additional_info': 'Check the collar region of trees frequently during summer months when adult beetles emerge and lay eggs.'
    }
  },
  'si': {
    'Thrips': {
      'scientific_name': 'Scirtothrips dorsalis',
      'severity': 'මධ්‍යම',
      'description': 'කොළ සහ මල් කොටස් වලින් යුෂ උරා බොන ඉතා කුඩා කෘමීන්. මේ නිසා අතු වර්ධනය බාල වී ගෙඩි වල කැළැල් ඇති වේ.',
      'symptoms': [
        'කජු ගෙඩි මතුපිට කුඩා කැළැල් ඇතිවීම',
        'කජු පුහුලම දුඹුරු පැහැ වී කොරපොතු ස්වභාවයක් ගැනීම',
        'පත්‍ර විවර්ණ වී හැකිලී යාම'
      ],
      'treatments': [
        {
          'name': 'කොහොඹ සාරය',
          'type': 'organic',
          'eco_friendly': true,
          'description': 'මල් පිපෙන කාලය තුළ NSKE (කොහොඹ ඇට සාරය) 5% ඉසින්න.',
          'timing': 'මල් පිපෙන/ඵල දරන අවධිය'
        },
        {
          'name': 'ප්‍රොෆෙනොෆොස්',
          'type': 'chemical',
          'eco_friendly': false,
          'description': 'හානිය දරුණු නම් ප්‍රොෆෙනොෆොස් 50 EC (ලීටරයකට මිලි ලීටර් 1) ඉසින්න.',
          'timing': 'කැළැල් පැහැදිලිව පෙනෙන විට'
        }
      ],
      'prevention': [
        {
           'measure': 'දළු නිරීක්ෂණය',
           'description': 'පළිබෝධ ගහනය වර්ධනය වීමට පෙර හඳුනාගැනීම සඳහා දිගින් දිගටම දළු ලියලන විට පරීක්ෂා කරන්න.'
        }
      ]
    },
    'mites': {
      'scientific_name': 'Tetranychidae',
      'severity': 'මධ්‍යම',
      'description': 'ශාක යුෂ මත යැපෙන මයිටාවන්. බොහෝ විට කජු කොළ යට පැත්තේ දැකිය හැකි අතර කොළ මත කුඩා ලප සහ දැල් ඇති කරයි.',
      'symptoms': [
        'කොළ මත කුඩා කහ හෝ සුදු පැහැති ලප',
        'කොළ යට පැත්තේ සියුම් දැල්',
        'හානියට පත් කොළ තඹ හෝ රිදී පැහැයක් ගැනීම',
        'දරුණු අවස්ථාවලදී පත්‍ර හැලී යාම'
      ],
      'treatments': [
         {
          'name': 'පරපෝෂිත මයිටාවන්',
          'type': 'biological',
          'eco_friendly': true,
          'description': 'Phytoseiulus persimilis හෝ වෙනත් පරපෝෂිත මයිටාවන් මුදාහරින්න.',
          'timing': 'හානියේ මුල් ලක්ෂණ දුටු විට'
        },
        {
          'name': 'තෙත් කළ හැකි ගෙන්දගම්',
          'type': 'chemical',
          'eco_friendly': false,
          'description': 'තෙත් කළ හැකි ගෙන්දගම් (ලීටරයකට ග්‍රෑම් 3ක්) ඉසින්න.',
          'timing': 'වියළි කාලගුණයක් පවතින විට',
          'frequency': 'දින 10-15 කට වරක්'
        }
      ],
      'prevention': [
         {
           'measure': 'නිසි ජල සම්පාදනය',
           'description': 'ජල හිඟය සහ උණුසුම් කාලගුණය මයිටාවන් බෝවීමට හිතකර වේ.'
         }
      ]
    },
    'stem_borer': {
      'scientific_name': 'Plocaederus ferrugineus',
      'severity': 'ඉහළ',
      'description': 'මුළු කජු ගසම විනාශ කළ හැකි මාරාන්තික පළිබෝධකයෙකි. කීටයන් ප්‍රධාන කඳේ සහ මුල්වල පොත්ත සහ දැවය සිදුරු කරයි.',
      'symptoms': [
        'පත්‍ර කහ වී අතු වියළී යාම',
        'ගස මුල සහ කඳේ කුඩා සිදුරු දක්නට ලැබීම',
        'ලාටු සමග මිශ්‍ර වූ කුඩු වැනි ද්‍රව්‍යයක් පිටතට පැමිණීම',
        'කොළ කහ වී හැලී යාම සහ ගස මිය යාම'
      ],
      'treatments': [
        {
          'name': 'යාන්ත්‍රිකව ඉවත් කිරීම',
          'type': 'mechanical',
          'eco_friendly': true,
          'description': 'සිදුරු වී ඇති ප්‍රදේශයේ පොත්ත ඉවත් කර කීටයා මරා දමන්න.',
          'timing': 'ආසාදනයේ මුල් අවධිය'
        },
        {
          'name': 'ක්ලෝරොපයිරිෆොස් ආලේප කිරීම',
          'type': 'chemical',
          'eco_friendly': false,
          'description': 'මීටර 1ක උසට කඳ සහ මතුපිටින් ඇති මුල් වල ක්ලෝරොපයිරිෆොස් 20 EC ගාන්න.',
          'timing': 'යාන්ත්‍රික ඉවත් කිරීමෙන් පසු',
          'frequency': 'වසරකට වරක්/දෙවරක්'
        }
      ],
      'prevention': [
        {
          'measure': 'ශාක සනීපාරක්ෂාව',
          'description': 'වෙනත් ගස්වලට පැතිරීම වැළැක්වීම සඳහා මියගිය සහ දැඩි ලෙස ආසාදිත ගස් ඉවත් කර පුළුස්සා දමන්න.',
          'frequency': 'ක්‍ෂණිකව'
        }
      ],
      'additional_info': 'ගිම්හාන මාසවලදී කෘමීන් බිත්තර දමන බැවින් කඳේ පහළ කොටස නිතර පරීක්ෂා කරන්න.'
    }
  },
  'ta': {
    'Thrips': {
      'scientific_name': 'Scirtothrips dorsalis',
      'severity': 'நடுத்தரமானது',
      'description': 'இலைகள் மற்றும் பூப் பகுதிகளில் இருந்து சாற்றை உறிஞ்சும் மிகச்சிறிய பூச்சிகள். இதனால் கிளைகள் வளர்ச்சி குன்றி கொட்டைகளில் வடுக்கள் ஏற்படும்.',
      'symptoms': [
        'முந்திரி கொட்டைகளின் மேற்பரப்பில் சொறி போன்ற வடுக்கள்',
        'பழங்களில் பழுப்பு நிற கறைகள்',
        'இலைகள் வெளிறி சுருங்குதல்'
      ],
      'treatments': [
        {
          'name': 'வேப்ப எண்ணெய்',
          'type': 'organic',
          'eco_friendly': true,
          'description': 'பூக்கும் காலத்தில் 5% வேப்பங்கொட்டை சாற்றை (NSKE) தெளிக்கவும்.',
          'timing': 'பூக்கும்/காய்க்கும் பருவம்'
        },
        {
          'name': 'புரொபெனோபாஸ் (Profenofos)',
          'type': 'chemical',
          'eco_friendly': false,
          'description': 'பாதிப்பு அதிகமாக இருந்தால் புரொபெனோபாஸ் 50 EC (1 மிலி/லிட்டர்) தெளிக்கவும்.',
          'timing': 'வடுக்கள் நன்கு தெரியும் போது'
        }
      ],
      'prevention': [
        {
           'measure': 'தளிர்களை கண்காணித்தல்',
           'description': 'பூச்சிகளின் பெருக்கத்தை முன்கூட்டியே கண்டறிய தளிர்களை தொடர்ந்து கண்காணிக்கவும்.'
        }
      ]
    },
    'mites': {
      'scientific_name': 'Tetranychidae',
      'severity': 'நடுத்தரமானது',
      'description': 'தாவர சாற்றை உண்ணும் சிலந்திப் பேன்கள். பொதுவாக முந்திரி இலைகளின் அடிப்பகுதியில் காணப்பட்டு, புள்ளிகள் மற்றும் வலைகளை உருவாக்குகின்றன.',
      'symptoms': [
        'இலைகளில் சிறிய மஞ்சள் அல்லது வெள்ளை புள்ளிகள்',
        'இலைகளின் அடிப்பகுதியில் மெல்லிய வலைகள்',
        'பாதிக்கப்பட்ட இலைகளில் வெண்கல அல்லது வெள்ளி நிறத் தோற்றம்',
        'கடுமையான சந்தர்ப்பங்களில் இலை உதிர்தல்'
      ],
      'treatments': [
         {
          'name': 'வேட்டையாடும் பேன்கள்',
          'type': 'biological',
          'eco_friendly': true,
          'description': 'Phytoseiulus persimilis அல்லது பிற வேட்டையாடும் பேன்களை விடவும்.',
          'timing': 'பாதிப்பின் ஆரம்ப அறிகுறிகள்'
        },
        {
          'name': 'ஈரப்படுத்தக்கூடிய கந்தகம்',
          'type': 'chemical',
          'eco_friendly': false,
          'description': 'ஈரப்படுத்தக்கூடிய கந்தகத்தை (3கிராம்/லிட்டர்) தெளிக்கவும்.',
          'timing': 'வறண்ட காலநிலையில்',
          'frequency': '10-15 நாட்களுக்கு ஒருமுறை'
        }
      ],
      'prevention': [
         {
           'measure': 'தகுந்த நீர்ப்பாசனம்',
           'description': 'நீர் பற்றாக்குறை மற்றும் வெப்பமான வானிலை சிலந்திப் பேன்கள் பெருக வழிவகுக்கும்.'
         }
      ]
    },
    'stem_borer': {
      'scientific_name': 'Plocaederus ferrugineus',
      'severity': 'அதிகமானது',
      'description': 'முழு முந்திரி மரத்தையும் கொல்லக்கூடிய ஒரு ஆபத்தான பூச்சி. புழுக்கள் முக்கிய தண்டு மற்றும் வேர்களின் பட்டை மற்றும் மரப்பகுதியில் துளைகளை உருவாக்குகின்றன.',
      'symptoms': [
        'இலைகள் மஞ்சள் நிறமாகி கிளைகள் காய்ந்து போதல்',
        'மரத்தின் அடியில் சிறிய துளைகள் காணப்படுதல்',
        'பசையுடன் கலந்த தூள் போன்ற கழிவுகள் வெளியேறுதல்',
        'இலைகள் காய்ந்து உதிர்ந்து மரம் இறந்து போதல்'
      ],
      'treatments': [
        {
          'name': 'இயந்திர முறை அகற்றம்',
          'type': 'mechanical',
          'eco_friendly': true,
          'description': 'துளையிடப்பட்ட பகுதியின் பட்டையை செதுக்கி புழுக்களைக் கொல்லுங்கள்.',
          'timing': 'ஆரம்ப நிலை பாதிப்பு'
        },
        {
          'name': 'குளோர்பைரிபாஸ் தடவுதல்',
          'type': 'chemical',
          'eco_friendly': false,
          'description': 'மரத்தின் தண்டு மற்றும் வேர்களில் 1 மீட்டர் உயரம் வரை குளோர்பைரிபாஸ் 20 EC தடவவும்.',
          'timing': 'புழுவை அகற்றிய பின்',
          'frequency': 'ஆண்டுக்கு ஒருமுறை/இருமுறை'
        }
      ],
      'prevention': [
        {
          'measure': 'சுய சுகாதாரம்',
          'description': 'மற்ற மரங்களுக்கு பரவுவதைத் தடுக்க இறந்த மற்றும் கடுமையாக பாதிக்கப்பட்ட மரங்களை அகற்றி எரிக்கவும்.',
          'frequency': 'உடனடியாக'
        }
      ],
      'additional_info': 'கோடை மாதங்களில் பூச்சிகள் முட்டையிடுவதால் மரத்தின் அடிப்பகுதியை அடிக்கடி பரிசோதிக்கவும்.'
    }
  }
};
