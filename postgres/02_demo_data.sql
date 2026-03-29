-- ==========================================
-- DEMO DATA
-- ==========================================

-- ==========================================
-- CORE.USERS
-- ==========================================
INSERT INTO core.users (email, password_hash, role, is_verified, is_active)
VALUES
    ('artist1@example.com', 'hash123', 'artist', TRUE, TRUE),
    ('artist2@example.com', 'hash123', 'artist', TRUE, TRUE),
    ('artist3@example.com', 'hash123', 'artist', TRUE, TRUE),
    ('venue1@example.com', 'hash123', 'venue_owner', TRUE, TRUE),
    ('venue2@example.com', 'hash123', 'venue_owner', TRUE, TRUE),
    ('admin@example.com', 'hash123', 'admin', TRUE, TRUE);

-- ==========================================
-- PROFILES.ARTISTS
-- ==========================================
INSERT INTO profiles.artists
(user_id, full_name, stage_name, bio, discography, genre, style, music_links, city, avg_audience_age, audience_profile, performance_type, minimum_fee, rider, contact_email, contact_phone)
VALUES
    (
        (SELECT id FROM core.users WHERE email='artist1@example.com'),
        'Иван Петров',
        'IvanP',
        'Музыкант, играющий рок и альтернативу',
        'Дискография: альбом "Начало", синглы "Свет", "Тьма"',
        'Рок',
        'Альтернатива',
        '["https://soundcloud.com/ivanp", "https://spotify.com/ivanp"]',
        'Москва',
        25,
        '{"gender": "mixed", "interests": ["rock", "live"]}',
        'Сольный',
        5000,
        'Полный технический райдер прилагается',
        'ivanp@example.com',
        '+79990001122'
    ),
    (
        (SELECT id FROM core.users WHERE email='artist2@example.com'),
        'Мария Смирнова',
        'MariaS',
        'Лирическая певица, автор песен',
        'Дискография: EP "Мечты", синглы "Весна", "Лето"',
        'Поп',
        'Лирика',
        '["https://soundcloud.com/marias", "https://spotify.com/marias"]',
        'Санкт-Петербург',
        22,
        '{"gender": "female", "interests": ["pop", "acoustic"]}',
        'Сольный',
        4000,
        'Стандартный райдер',
        'marias@example.com',
        '+79991112233'
    ),
    (
        (SELECT id FROM core.users WHERE email='artist3@example.com'),
        'Алексей Козлов',
        'AlexK',
        'Диджей, играющий хаус и техно',
        'Дискография: синглы "Nightlife", "Dancefloor"',
        'Электронная',
        'Хаус/Техно',
        '["https://soundcloud.com/alexk", "https://spotify.com/alexk"]',
        'Москва',
        27,
        '{"gender": "mixed", "interests": ["dance", "party"]}',
        'Сольный',
        6000,
        'Технический райдер для клубов',
        'alexk@example.com',
        '+79992223344'
    );

-- ==========================================
-- PROFILES.VENUES
-- ==========================================
INSERT INTO profiles.venues
(user_id, name, venue_type, city, address, capacity, avg_ticket_price, has_stage, has_sound_system, has_lighting, contact_email, contact_phone, concept, audience_description, avg_audience_age)
VALUES
    (
        (SELECT id FROM core.users WHERE email='venue1@example.com'),
        'ClubMoscow',
        'Клуб',
        'Москва',
        'ул. Пушкина, д. 10',
        200,
        1500,
        TRUE,
        TRUE,
        TRUE,
        'club1@example.com',
        '+79991112233',
        'Электронная музыка, вечеринки по пятницам',
        'Молодая аудитория 18-35 лет, любители хауса и техно',
        25
    ),
    (
        (SELECT id FROM core.users WHERE email='venue2@example.com'),
        'SPBHall',
        'Концертный зал',
        'Санкт-Петербург',
        'Невский проспект, д. 100',
        500,
        2500,
        TRUE,
        TRUE,
        TRUE,
        'hall2@example.com',
        '+79994445566',
        'Поп и эстрадные концерты',
        'Семейная и взрослая аудитория, любители поп-музыки',
        30
    );

-- ==========================================
-- MARKETPLACE.VENUE_REQUESTS
-- ==========================================
INSERT INTO marketplace.venue_requests
(venue_id, title, description, event_date, budget_min, budget_max, required_genres, performance_type, requirements, equipment_provided)
VALUES
    (
        (SELECT id FROM profiles.venues WHERE name='ClubMoscow'),
        'Ночная вечеринка',
        'Ищем диджея для пятничной вечеринки',
        '2026-05-15',
        10000,
        20000,
        '["Электронная", "Хаус", "Техно"]',
        'Сольный',
        'Опыт работы с клубной аудиторией, наличие собственных треков',
        'Звук, свет, бар'
    ),
    (
        (SELECT id FROM profiles.venues WHERE name='SPBHall'),
        'Концерт поп-исполнителей',
        'Ищем поп-группу для семейного концерта',
        '2026-06-01',
        15000,
        30000,
        '["Поп"]',
        'Сольный',
        'Опыт живых концертов, наличие репертуара',
        'Сценическое оборудование, микрофоны'
    );

-- ==========================================
-- MARKETPLACE.APPLICATIONS
-- ==========================================
INSERT INTO marketplace.applications
(artist_id, venue_id, venue_request_id, proposed_date, proposed_fee, message)
VALUES
    (
        (SELECT id FROM profiles.artists WHERE stage_name='AlexK'),
        (SELECT id FROM profiles.venues WHERE name='ClubMoscow'),
        (SELECT id FROM marketplace.venue_requests WHERE title='Ночная вечеринка'),
        '2026-05-15',
        12000,
        'Готов выступить в клубе с полным набором оборудования'
    ),
    (
        (SELECT id FROM profiles.artists WHERE stage_name='MariaS'),
        (SELECT id FROM profiles.venues WHERE name='SPBHall'),
        (SELECT id FROM marketplace.venue_requests WHERE title='Концерт поп-исполнителей'),
        '2026-06-01',
        20000,
        'Имею опыт выступлений для семейной аудитории, готова к сотрудничеству'
    );

-- ==========================================
-- MARKETPLACE.CONVERSATIONS
-- ==========================================
INSERT INTO marketplace.conversations
(artist_id, venue_id, application_id)
VALUES
    (
        (SELECT id FROM profiles.artists WHERE stage_name='AlexK'),
        (SELECT id FROM profiles.venues WHERE name='ClubMoscow'),
        (SELECT id FROM marketplace.applications WHERE proposed_fee=12000)
    ),
    (
        (SELECT id FROM profiles.artists WHERE stage_name='MariaS'),
        (SELECT id FROM profiles.venues WHERE name='SPBHall'),
        (SELECT id FROM marketplace.applications WHERE proposed_fee=20000)
    );

-- ==========================================
-- MARKETPLACE.MESSAGES
-- ==========================================
INSERT INTO marketplace.messages
(conversation_id, sender_id, message_text, is_read)
VALUES
    (
        (SELECT id FROM marketplace.conversations
         WHERE artist_id=(SELECT id FROM profiles.artists WHERE stage_name='AlexK')
           AND venue_id=(SELECT id FROM profiles.venues WHERE name='ClubMoscow')),
        (SELECT id FROM core.users WHERE email='artist3@example.com'),
        'Привет! Я готов выступить с полным диджей-сетом.',
        TRUE
    ),
    (
        (SELECT id FROM marketplace.conversations
         WHERE artist_id=(SELECT id FROM profiles.artists WHERE stage_name='AlexK')
           AND venue_id=(SELECT id FROM profiles.venues WHERE name='ClubMoscow')),
        (SELECT id FROM core.users WHERE email='venue1@example.com'),
        'Отлично, Алексей! Уточним детали по звуку и свету.',
        FALSE
    ),
    (
        (SELECT id FROM marketplace.conversations
         WHERE artist_id=(SELECT id FROM profiles.artists WHERE stage_name='MariaS')
           AND venue_id=(SELECT id FROM profiles.venues WHERE name='SPBHall')),
        (SELECT id FROM core.users WHERE email='artist2@example.com'),
        'Добрый день! Я могу выступить на вашем семейном концерте.',
        TRUE
    ),
    (
        (SELECT id FROM marketplace.conversations
         WHERE artist_id=(SELECT id FROM profiles.artists WHERE stage_name='MariaS')
           AND venue_id=(SELECT id FROM profiles.venues WHERE name='SPBHall')),
        (SELECT id FROM core.users WHERE email='venue2@example.com'),
        'Спасибо, Мария! Мы обсудим сет-лист и тайминг выступления.',
        FALSE
    );