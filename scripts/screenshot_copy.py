"""스토어 그림 문구 — 언어마다 따로 쓴다(직역 금지). 마케팅 스크린샷 · 헤더 · 검색 결과가 함께 쓴다.

MARKETING[로케일] = [(헤드라인, 보조 한 줄) × 4]   01-today · 02-calendar · 03-stats · 04-goal 순서. 아이패드는 앞 3장.
HEADER[로케일]    = (눈썹글, 헤드라인)                한 가지 약속: 햇빛을 모아 해바라기를 키운다
SEARCH[로케일]    = (눈썹글=그 나라 검색어, 헤드라인, 보조 한 줄)   스크린샷 1장과 같은 이야기
"""

MARKETING = {
    "ko": [
        ("햇빛을 받을수록<br>해바라기가 자라요", "밖에 나가면 밝기를 재서 햇빛 시간을 모아요"),
        ("하루 햇빛과 기분을<br>한눈에", "날짜마다 햇빛 시간, 기분, 한마디를 남겨요"),
        ("이번 주 햇빛,<br>얼마나 받았을까", "일별 햇빛 시간과 목표 달성을 그래프로"),
        ("나에게 맞는<br>하루 목표", "10분부터 120분까지, 알림 시간도 내 마음대로"),
    ],
    "en": [
        ("The more sun you get,<br>the taller it grows", "Head outside and it measures the light to log your sun time"),
        ("Your sunlight and mood,<br>day by day", "Sun minutes, mood and a quick note for every day"),
        ("How much sun<br>did you get this week?", "Daily sun time and goal progress in one chart"),
        ("A daily goal<br>that suits you", "Anywhere from 10 to 120 minutes, reminders when you want"),
    ],
    "en-GB": [
        ("The more sun you get,<br>the taller it grows", "Pop outside and it measures the light to log your sun time"),
        ("Your daylight and mood,<br>day by day", "Sun minutes, mood and a quick note for every day"),
        ("How much sun<br>did you get this week?", "Daily sun time and goal progress at a glance"),
        ("Your daily goal,<br>your way", "Anything from 10 to 120 minutes, reminders when you like"),
    ],
    "zh-Hans": [
        ("晒得越多，<br>向日葵长得越高", "出门晒太阳，自动测量亮度记录日照时间"),
        ("每天的阳光与心情<br>一目了然", "按日期记录日照时长、心情和一句话"),
        ("这周晒了<br>多少太阳？", "每日日照时长与目标达成，图表一看便知"),
        ("适合自己的<br>每日目标", "10 到 120 分钟随心设定，提醒时间自己定"),
    ],
    "zh-Hant": [
        ("曬得越多，<br>向日葵長得越高", "到戶外曬太陽，自動偵測亮度記錄日照時間"),
        ("每天的陽光與心情<br>一目瞭然", "依日期記下日照時間、心情和一句話"),
        ("這週曬了<br>多少太陽？", "每日日照時間與目標達成，用圖表一看就懂"),
        ("適合自己的<br>每日目標", "10 到 120 分鐘自由設定，提醒時間也由你決定"),
    ],
    "ja": [
        ("日を浴びるほど<br>ひまわりが育つ", "外に出ると明るさを測って日光浴の時間を記録"),
        ("毎日の日差しと気分を<br>ひと目で", "日付ごとに日光浴の時間、気分、ひとことを残せます"),
        ("今週は<br>どれだけ浴びた？", "毎日の日光浴時間と目標達成をグラフで"),
        ("自分にちょうどいい<br>毎日の目標", "10分から120分まで、通知の時間も自由に"),
    ],
    "ru": [
        ("Чем больше солнца,<br>тем выше подсолнух", "На улице приложение измеряет свет и копит минуты на солнце"),
        ("Солнце и настроение<br>каждого дня", "Минуты на солнце, настроение и короткая заметка за день"),
        ("Сколько солнца<br>было на этой неделе?", "Время на солнце и цели на графике"),
        ("Цель на день —<br>в вашем ритме", "От 10 до 120 минут, напоминания в удобное время"),
    ],
    "es": [
        ("Cuanto más sol tomas,<br>más crece tu girasol", "Al salir mide la luz y suma tu tiempo al sol"),
        ("Tu sol y tu ánimo,<br>día a día", "Minutos de sol, estado de ánimo y una nota para cada día"),
        ("¿Cuánto sol tomaste<br>esta semana?", "Tu sol diario y tus metas, en un gráfico"),
        ("Una meta diaria<br>a tu medida", "De 10 a 120 minutos y recordatorios cuando quieras"),
    ],
    "de": [
        ("Je mehr Sonne,<br>desto größer die Blume", "Draußen misst die App das Licht und sammelt deine Sonnenzeit"),
        ("Sonne und Stimmung<br>auf einen Blick", "Sonnenminuten, Stimmung und eine kurze Notiz für jeden Tag"),
        ("Wie viel Sonne hattest<br>du diese Woche?", "Sonnenzeit und Ziele im Diagramm"),
        ("Ein Tagesziel,<br>das zu dir passt", "Von 10 bis 120 Minuten, Erinnerung zur Wunschzeit"),
    ],
    "fr": [
        ("Plus tu prends le soleil,<br>plus il grandit", "Dehors, l’app mesure la lumière et compte ton temps au soleil"),
        ("Ton soleil et ton humeur,<br>jour après jour", "Minutes de soleil, humeur et petite note pour chaque jour"),
        ("Combien de soleil<br>cette semaine&nbsp;?", "Ton soleil et tes objectifs en graphique"),
        ("Un objectif quotidien<br>à ta mesure", "De 10 à 120 minutes, rappels à l’heure de ton choix"),
    ],
    "it": [
        ("Più sole prendi,<br>più cresce il girasole", "All’aperto misura la luce e raccoglie il tuo tempo al sole"),
        ("Sole e umore,<br>giorno per giorno", "Minuti di sole, umore e una nota per ogni giornata"),
        ("Quanto sole hai preso<br>questa settimana?", "Sole giornaliero e obiettivi in un grafico"),
        ("Un obiettivo giornaliero<br>su misura", "Da 10 a 120 minuti, promemoria all’ora che vuoi"),
    ],
    "pt-BR": [
        ("Quanto mais sol,<br>mais ele cresce", "Ao sair, o app mede a luz e soma seu tempo no sol"),
        ("Seu sol e seu humor<br>dia a dia", "Minutos de sol, humor e uma anotação para cada dia"),
        ("Quanto sol você tomou<br>nesta semana?", "Tempo de sol diário e metas cumpridas em gráfico"),
        ("Uma meta diária<br>do seu jeito", "De 10 a 120 minutos, com lembretes na hora que quiser"),
    ],
    "th": [
        ("ยิ่งรับแดดมาก<br>ทานตะวันยิ่งโต", "ออกไปข้างนอก แอปจะวัดแสงและเก็บเวลารับแดดให้"),
        ("แดดและอารมณ์แต่ละวัน<br>ดูได้ในหน้าเดียว", "บันทึกเวลารับแดด อารมณ์ และข้อความสั้นๆ ได้ทุกวัน"),
        ("สัปดาห์นี้<br>รับแดดไปเท่าไร", "ดูเวลารับแดดรายวันและเป้าหมายที่ทำได้เป็นกราฟ"),
        ("เป้าหมายรายวัน<br>ที่ใช่สำหรับคุณ", "ตั้งได้ตั้งแต่ 10 ถึง 120 นาที เลือกเวลาแจ้งเตือนเองได้"),
    ],
    "vi": [
        ("Càng đón nắng,<br>hoa càng lớn", "Ra ngoài trời, app đo ánh sáng và cộng dồn thời gian đón nắng"),
        ("Nắng và tâm trạng<br>mỗi ngày", "Ghi số phút đón nắng, tâm trạng và một dòng ghi chú"),
        ("Tuần này bạn<br>đón nắng bao lâu?", "Giờ đón nắng và mục tiêu trên biểu đồ"),
        ("Mục tiêu mỗi ngày<br>hợp với bạn", "Từ 10 đến 120 phút, nhắc nhở vào giờ bạn chọn"),
    ],
    "cs": [
        ("Čím víc slunce,<br>tím víc roste", "Venku měří světlo a sčítá tvůj čas na slunci"),
        ("Slunce a nálada<br>den po dni", "Minuty na slunci, nálada a krátká poznámka ke každému dni"),
        ("Kolik slunce<br>tento týden?", "Denní čas na slunci a splněné cíle v grafu"),
        ("Denní cíl<br>podle tebe", "Od 10 do 120 minut, připomínka v čase, který si zvolíš"),
    ],
    "da": [
        ("Jo mere sol,<br>jo større solsikke", "Udenfor måler appen lyset og samler din tid i solen"),
        ("Sol og humør<br>dag for dag", "Solminutter, humør og en lille note for hver dag"),
        ("Hvor meget sol fik du<br>i denne uge?", "Daglig soltid og nåede mål i et diagram"),
        ("Et dagligt mål,<br>der passer dig", "Fra 10 til 120 minutter og påmindelser, når du vil"),
    ],
    "el": [
        ("Όσο περισσότερο ήλιο,<br>τόσο ψηλώνει", "Έξω μετρά το φως και μαζεύει τον χρόνο σου στον ήλιο"),
        ("Ήλιος και διάθεση,<br>μέρα με τη μέρα", "Λεπτά στον ήλιο, διάθεση και μια σύντομη σημείωση κάθε μέρα"),
        ("Πόσο ήλιο πήρες<br>αυτή την εβδομάδα;", "Χρόνος στον ήλιο και στόχοι σε γράφημα"),
        ("Ημερήσιος στόχος<br>στα μέτρα σου", "Από 10 έως 120 λεπτά, με υπενθύμιση όποια ώρα θέλεις"),
    ],
    "fi": [
        ("Mitä enemmän aurinkoa,<br>sitä isompi kukka", "Ulkona sovellus mittaa valoa ja kerää aurinkoaikasi"),
        ("Aurinko ja mieliala<br>päivä päivältä", "Aurinkominuutit, mieliala ja lyhyt muistiinpano joka päivälle"),
        ("Paljonko aurinkoa<br>tällä viikolla?", "Aurinkoaika ja tavoitteet kaaviona"),
        ("Päivätavoite,<br>joka sopii sinulle", "10–120 minuuttia ja muistutus juuri silloin kun haluat"),
    ],
    "id": [
        ("Makin sering berjemur,<br>makin tinggi bunganya", "Di luar, app mengukur cahaya dan mencatat waktu berjemurmu"),
        ("Sinar dan mood<br>setiap hari", "Catat menit berjemur, suasana hati, dan catatan singkat"),
        ("Berapa lama berjemur<br>minggu ini?", "Waktu berjemur dan target dalam grafik"),
        ("Target harian<br>sesuai dirimu", "Dari 10 sampai 120 menit, pengingat di jam pilihanmu"),
    ],
    "nb": [
        ("Jo mer sol,<br>jo større solsikke", "Ute måler appen lyset og samler tiden din i sola"),
        ("Sol og humør<br>dag for dag", "Solminutter, humør og et lite notat for hver dag"),
        ("Hvor mye sol fikk du<br>denne uka?", "Daglig soltid og nådde mål i et diagram"),
        ("Et dagsmål<br>som passer deg", "Fra 10 til 120 minutter, med påminnelse når du vil"),
    ],
    "nl": [
        ("Hoe meer zon,<br>hoe groter je bloem", "Buiten meet de app het licht en telt je tijd in de zon"),
        ("Zon en stemming<br>per dag", "Zonminuten, stemming en een korte notitie voor elke dag"),
        ("Hoeveel zon had je<br>deze week?", "Zontijd en doelen in een grafiek"),
        ("Een dagdoel<br>dat bij je past", "Van 10 tot 120 minuten, herinneringen wanneer jij wilt"),
    ],
    "pl": [
        ("Im więcej słońca,<br>tym wyższy słonecznik", "Na dworze aplikacja mierzy światło i liczy Twój czas na słońcu"),
        ("Słońce i nastrój<br>dzień po dniu", "Minuty na słońcu, nastrój i krótka notatka do każdego dnia"),
        ("Ile słońca<br>w tym tygodniu?", "Czas na słońcu i cele na wykresie"),
        ("Dzienny cel<br>na Twoją miarę", "Od 10 do 120 minut, przypomnienia o wybranej porze"),
    ],
    "sv": [
        ("Ju mer sol,<br>desto större solros", "Utomhus mäter appen ljuset och samlar din tid i solen"),
        ("Sol och humör<br>dag för dag", "Solminuter, humör och en kort anteckning för varje dag"),
        ("Hur mycket sol fick du<br>den här veckan?", "Daglig soltid och uppnådda mål i ett diagram"),
        ("Ett dagsmål<br>som passar dig", "Från 10 till 120 minuter, påminnelser när du vill"),
    ],
    "tr": [
        ("Güneş aldıkça<br>ayçiçeğin büyür", "Dışarı çıkınca ışığı ölçer, güneşte geçen süreni toplar"),
        ("Her günün güneşi<br>ve ruh hâli", "Her gün için güneş dakikaları, ruh hâli ve kısa bir not"),
        ("Bu hafta ne kadar<br>güneş aldın?", "Güneş süresi ve hedefler grafikte"),
        ("Sana uygun<br>günlük hedef", "10 ile 120 dakika arası, hatırlatma istediğin saatte"),
    ],
}

HEADER = {
    "ko": ("하루 한 줌의 햇빛", "햇빛을 모아<br>해바라기를 키워요"),
    "en": ("A little sunshine every day", "Soak up the sun,<br>grow your sunflower"),
    "en-GB": ("A bit of sunshine every day", "Soak up the sun,<br>grow your sunflower"),
    "zh-Hans": ("每天一把阳光", "收集阳光，<br>养大你的向日葵"),
    "zh-Hant": ("每天一點點陽光", "收集陽光，<br>養大你的向日葵"),
    "ja": ("毎日ひとにぎりの日差し", "日差しを集めて<br>ひまわりを育てよう"),
    "ru": ("Немного солнца каждый день", "Собирайте солнце —<br>растите подсолнух"),
    "es": ("Un poco de sol cada día", "Toma el sol y haz<br>crecer tu girasol"),
    "de": ("Jeden Tag ein bisschen Sonne", "Sonne tanken,<br>Sonnenblume wachsen lassen"),
    "fr": ("Un peu de soleil chaque jour", "Fais le plein de soleil,<br>fais grandir ton tournesol"),
    "it": ("Un po’ di sole ogni giorno", "Raccogli il sole,<br>fai crescere il girasole"),
    "pt-BR": ("Um pouco de sol todo dia", "Junte sol e faça<br>seu girassol crescer"),
    "th": ("รับแดดวันละนิด", "เก็บแสงแดด<br>ปลูกทานตะวันของคุณ"),
    "vi": ("Mỗi ngày một chút nắng", "Gom nắng để<br>hoa hướng dương lớn lên"),
    "cs": ("Každý den kousek slunce", "Sbírej slunce,<br>pěstuj slunečnici"),
    "da": ("Lidt sol hver dag", "Saml sol, og få<br>din solsikke til at gro"),
    "el": ("Λίγος ήλιος κάθε μέρα", "Μάζεψε ήλιο,<br>μεγάλωσε το ηλιοτρόπιό σου"),
    "fi": ("Vähän aurinkoa joka päivä", "Kerää aurinkoa,<br>kasvata auringonkukka"),
    "id": ("Sedikit sinar matahari tiap hari", "Kumpulkan sinar matahari,<br>tumbuhkan bungamu"),
    "nb": ("Litt sol hver dag", "Samle sol,<br>la solsikken vokse"),
    "nl": ("Elke dag een beetje zon", "Verzamel zonlicht,<br>laat je zonnebloem groeien"),
    "pl": ("Trochę słońca każdego dnia", "Zbieraj słońce,<br>hoduj słonecznik"),
    "sv": ("Lite sol varje dag", "Samla sol,<br>låt din solros växa"),
    "tr": ("Her gün biraz güneş", "Güneşi topla,<br>ayçiçeğini büyüt"),
}

SEARCH = {
    "ko": ("햇빛 산책 기록", "오늘 받은 햇빛,<br>알아서 기록", "밖에 나가 햇빛을 쬐면 하루 목표까지 채워져요"),
    "en": ("Sunlight tracker", "Your daily sunlight,<br>logged for you", "Step outside and watch your daily goal fill up"),
    "en-GB": ("Daylight tracker", "Today’s daylight,<br>logged for you", "Pop outside and watch your daily goal fill up"),
    "zh-Hans": ("晒太阳打卡", "今天晒的太阳，<br>自动帮你记", "出门晒晒太阳，<br>每日目标轻松达成"),
    "zh-Hant": ("曬太陽紀錄", "今天曬的太陽，<br>自動幫你記", "出門曬曬太陽，<br>每日目標輕鬆達成"),
    "ja": ("日光浴 記録", "今日浴びた日差しを<br>自動で記録", "外で日を浴びれば、<br>毎日の目標が満たされていく"),
    "ru": ("Трекер солнца", "Минуты на солнце<br>считаются сами", "Выйдите на улицу — и дневная цель заполнится"),
    "es": ("Registro de sol", "Tu sol de hoy,<br>registrado solo", "Sal a tomar el sol y completa tu meta diaria"),
    "de": ("Sonnenlicht-Tracker", "Deine Sonne heute,<br>schon notiert", "Geh raus in die Sonne und erreiche dein Tagesziel"),
    "fr": ("Suivi soleil", "Ton soleil du jour,<br>noté tout seul", "Sors prendre le soleil et atteins ton objectif du jour"),
    "it": ("Tracker luce solare", "Il sole di oggi,<br>registrato da solo", "Esci al sole e completa il tuo obiettivo del giorno"),
    "pt-BR": ("Registro de sol", "Seu sol de hoje,<br>anotado sozinho", "Saia para tomar sol e complete sua meta diária"),
    "th": ("บันทึกการรับแดด", "แดดที่ได้รับวันนี้<br>บันทึกให้อัตโนมัติ", "ออกไปรับแดดข้างนอก แล้วเป้าหมายวันนี้ก็เต็ม"),
    "vi": ("Theo dõi ánh nắng", "Nắng hôm nay,<br>tự động ghi lại", "Ra ngoài đón nắng là mục tiêu mỗi ngày đầy dần"),
    "cs": ("Sledování slunce", "Dnešní slunce<br>se zapíše samo", "Vyjdi na slunce a splň svůj denní cíl"),
    "da": ("Sollys tracker", "Dagens sol<br>logges af sig selv", "Gå ud i solen, og se dit dagsmål blive fyldt op"),
    "el": ("Καταγραφή ηλιοφάνειας", "Ο ήλιος της μέρας<br>γράφεται μόνος", "Βγες στον ήλιο και γέμισε τον ημερήσιο στόχο σου"),
    "fi": ("Auringonvalon seuranta", "Päivän aurinko<br>kirjautuu itsestään", "Lähde ulos aurinkoon ja täytä päivätavoitteesi"),
    "id": ("Pencatat berjemur", "Berjemur hari ini<br>tercatat otomatis", "Keluar dan berjemur, target harianmu pun terpenuhi"),
    "nb": ("Sollys-sporing", "Dagens sol<br>logges automatisk", "Gå ut i sola og fyll opp dagsmålet ditt"),
    "nl": ("Zonlicht tracker", "Zon van vandaag,<br>vanzelf genoteerd", "Ga naar buiten en vul je dagdoel met zonlicht"),
    "pl": ("Licznik słońca", "Dzisiejsze słońce<br>zapisane samo", "Wyjdź na słońce i wypełnij swój dzienny cel"),
    "sv": ("Solljus tracker", "Dagens sol<br>loggas av sig själv", "Gå ut i solen och fyll ditt dagsmål"),
    "tr": ("Güneş takibi", "Bugünün güneşi<br>otomatik kayıtta", "Dışarı çık, güneşlen ve günlük hedefini doldur"),
}

# 글꼴: 같은 한자라도 언어마다 글리프가 다르다. html lang 과 함께 쓴다.
FONTS = {
    "ja": '"Hiragino Sans", "Hiragino Kaku Gothic ProN"',
    "zh-Hans": '"PingFang SC"',
    "zh-Hant": '"PingFang TC"',
    "th": '"Sukhumvit Set", "Thonburi"',
    "ko": '"Apple SD Gothic Neo"',
}


def font_stack(lang):
    return f'-apple-system, "SF Pro Display", {FONTS.get(lang, "")}{", " if lang in FONTS else ""}"Helvetica Neue", sans-serif'
