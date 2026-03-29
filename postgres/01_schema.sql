-- ==========================================
-- EXTENSIONS
-- ==========================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- SCHEMAS
-- ==========================================
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS profiles;
CREATE SCHEMA IF NOT EXISTS marketplace;
CREATE SCHEMA IF NOT EXISTS analytics;

-- ==========================================
-- FUNCTION
-- ==========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- ENUMS
-- ==========================================
DO $$ BEGIN
CREATE TYPE user_role AS ENUM ('artist', 'venue_owner', 'admin');
CREATE TYPE request_status AS ENUM ('open', 'closed', 'cancelled');
CREATE TYPE application_status AS ENUM ('pending', 'accepted', 'rejected', 'cancelled');
CREATE TYPE booking_status AS ENUM ('confirmed', 'completed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ==========================================
-- CORE.USERS
-- ==========================================
CREATE TABLE core.users (
                            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                            email VARCHAR(255) NOT NULL UNIQUE,
                            password_hash VARCHAR(255) NOT NULL,
                            role user_role NOT NULL DEFAULT 'artist',
                            is_verified BOOLEAN NOT NULL DEFAULT FALSE,
                            is_active BOOLEAN NOT NULL DEFAULT TRUE,
                            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            last_login_at TIMESTAMP
);

CREATE TRIGGER trg_users_updated
    BEFORE UPDATE ON core.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_users_role ON core.users(role);

-- ==========================================
-- PROFILES.ARTISTS
-- ==========================================
CREATE TABLE profiles.artists (
                                  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                                  user_id UUID NOT NULL UNIQUE REFERENCES core.users(id) ON DELETE CASCADE,

                                  full_name VARCHAR(255),
                                  stage_name VARCHAR(255) NOT NULL,

                                  bio TEXT,
                                  discography TEXT,

                                  genre VARCHAR(100),
                                  style VARCHAR(255),

                                  music_links JSONB,

                                  city VARCHAR(100) NOT NULL,

                                  avg_audience_age INT CHECK (
                                      avg_audience_age IS NULL OR avg_audience_age BETWEEN 10 AND 100
                                      ),

                                  audience_profile JSONB,

                                  performance_type VARCHAR(50),
                                  minimum_fee NUMERIC(12,2) CHECK (minimum_fee >= 0),

                                  rider TEXT,

                                  contact_email VARCHAR(255),
                                  contact_phone VARCHAR(50),

                                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_artists_updated
    BEFORE UPDATE ON profiles.artists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_artists_city ON profiles.artists(city);
CREATE INDEX idx_artists_genre ON profiles.artists(genre);
CREATE INDEX idx_artists_style ON profiles.artists(style);
CREATE INDEX idx_artists_fee ON profiles.artists(minimum_fee);

-- ==========================================
-- PROFILES.VENUES
-- ==========================================
CREATE TABLE profiles.venues (
                                 id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                                 user_id UUID NOT NULL UNIQUE REFERENCES core.users(id) ON DELETE CASCADE,

                                 name VARCHAR(255) NOT NULL,
                                 concept TEXT,

                                 venue_type VARCHAR(50),

                                 capacity INT CHECK (capacity >= 0),
                                 avg_ticket_price NUMERIC(10,2) CHECK (avg_ticket_price >= 0),

                                 address TEXT NOT NULL,
                                 city VARCHAR(100) NOT NULL,

                                 work_schedule JSONB,

                                 avg_audience_age INT CHECK (
                                     avg_audience_age IS NULL OR avg_audience_age BETWEEN 10 AND 100
                                     ),

                                 audience_description TEXT,
                                 preferred_genres JSONB,

                                 has_sound_system BOOLEAN DEFAULT FALSE,
                                 has_stage BOOLEAN DEFAULT FALSE,
                                 has_lighting BOOLEAN DEFAULT FALSE,

                                 contact_email VARCHAR(255),
                                 contact_phone VARCHAR(50),

                                 photos_urls JSONB,

                                 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_venues_updated
    BEFORE UPDATE ON profiles.venues
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_venues_city ON profiles.venues(city);
CREATE INDEX idx_venues_capacity ON profiles.venues(capacity);
CREATE INDEX idx_venues_type ON profiles.venues(venue_type);

-- ==========================================
-- MARKETPLACE.VENUE_REQUESTS
-- ==========================================
CREATE TABLE marketplace.venue_requests (
                                            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                                            venue_id UUID NOT NULL REFERENCES profiles.venues(id) ON DELETE CASCADE,

                                            title VARCHAR(255) NOT NULL,
                                            description TEXT,

                                            event_date DATE,

                                            budget_min NUMERIC(12,2) CHECK (budget_min >= 0),
                                            budget_max NUMERIC(12,2) CHECK (budget_max >= 0),

                                            required_genres JSONB,
                                            performance_type VARCHAR(50),

                                            requirements TEXT,
                                            equipment_provided TEXT,

                                            status request_status NOT NULL DEFAULT 'open',

                                            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                                            CHECK (
                                                budget_min IS NULL OR budget_max IS NULL OR budget_min <= budget_max
                                                )
);

CREATE TRIGGER trg_requests_updated
    BEFORE UPDATE ON marketplace.venue_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_requests_venue ON marketplace.venue_requests(venue_id);
CREATE INDEX idx_requests_status ON marketplace.venue_requests(status);
CREATE INDEX idx_requests_date ON marketplace.venue_requests(event_date);

-- ==========================================
-- MARKETPLACE.APPLICATIONS
-- ==========================================
CREATE TABLE marketplace.applications (
                                          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                                          artist_id UUID NOT NULL REFERENCES profiles.artists(id) ON DELETE CASCADE,
                                          venue_id UUID NOT NULL REFERENCES profiles.venues(id) ON DELETE CASCADE,

                                          venue_request_id UUID NOT NULL REFERENCES marketplace.venue_requests(id) ON DELETE CASCADE,

                                          proposed_date DATE,
                                          proposed_fee NUMERIC(12,2) CHECK (proposed_fee >= 0),

                                          message TEXT,

                                          status application_status NOT NULL DEFAULT 'pending',

                                          created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                          updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                                          UNIQUE (artist_id, venue_request_id)
);

CREATE TRIGGER trg_applications_updated
    BEFORE UPDATE ON marketplace.applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_app_artist ON marketplace.applications(artist_id);
CREATE INDEX idx_app_venue ON marketplace.applications(venue_id);
CREATE INDEX idx_app_status ON marketplace.applications(status);

-- ==========================================
-- MARKETPLACE.CONVERSATIONS
-- ==========================================
CREATE TABLE marketplace.conversations (
                                           id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                                           artist_id UUID REFERENCES profiles.artists(id),
                                           venue_id UUID REFERENCES profiles.venues(id),

                                           application_id UUID REFERENCES marketplace.applications(id) ON DELETE SET NULL,
                                           booking_id UUID,

                                           created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                                           CHECK (
                                               artist_id IS NOT NULL OR venue_id IS NOT NULL
                                               )
);

-- ==========================================
-- MARKETPLACE.MESSAGES
-- ==========================================
CREATE TABLE marketplace.messages (
                                      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                                      conversation_id UUID NOT NULL REFERENCES marketplace.conversations(id) ON DELETE CASCADE,
                                      sender_id UUID NOT NULL REFERENCES core.users(id) ON DELETE CASCADE,

                                      message_text TEXT NOT NULL,
                                      is_read BOOLEAN NOT NULL DEFAULT FALSE,

                                      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_messages_conversation ON marketplace.messages(conversation_id);

-- ==========================================
-- MARKETPLACE.BOOKINGS
-- ==========================================
CREATE TABLE marketplace.bookings (
                                      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                                      application_id UUID REFERENCES marketplace.applications(id) ON DELETE SET NULL,
                                      venue_request_id UUID REFERENCES marketplace.venue_requests(id) ON DELETE SET NULL,

                                      artist_id UUID NOT NULL REFERENCES profiles.artists(id),
                                      venue_id UUID NOT NULL REFERENCES profiles.venues(id),

                                      event_date DATE NOT NULL,

                                      agreed_fee NUMERIC(12,2) CHECK (agreed_fee >= 0),
                                      platform_fee NUMERIC(12,2) CHECK (platform_fee >= 0),

                                      status booking_status NOT NULL DEFAULT 'confirmed',

                                      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                                      UNIQUE (artist_id, event_date)
);

CREATE TRIGGER trg_bookings_updated
    BEFORE UPDATE ON marketplace.bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_bookings_artist ON marketplace.bookings(artist_id);
CREATE INDEX idx_bookings_venue ON marketplace.bookings(venue_id);
CREATE INDEX idx_bookings_date ON marketplace.bookings(event_date);

-- ==========================================
-- ANALYTICS.PERFORMANCES
-- ==========================================
CREATE TABLE analytics.performances (
                                        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                                        artist_id UUID NOT NULL REFERENCES profiles.artists(id),
                                        venue_id UUID NOT NULL REFERENCES profiles.venues(id),

                                        event_date DATE NOT NULL,

                                        attendance_count INT CHECK (attendance_count >= 0),
                                        success_rating VARCHAR(50),

                                        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_perf_updated
    BEFORE UPDATE ON analytics.performances
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- ANALYTICS.ARTIST_METRICS
-- ==========================================
CREATE TABLE analytics.artist_metrics (
                                          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                                          artist_id UUID NOT NULL REFERENCES profiles.artists(id),

                                          period_start DATE NOT NULL,
                                          period_end DATE NOT NULL,

                                          listens_total INT DEFAULT 0 CHECK (listens_total >= 0),
                                          listeners_unique INT DEFAULT 0 CHECK (listeners_unique >= 0),

                                          created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                          updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                                          CHECK (period_start <= period_end)
);

CREATE INDEX idx_artist_metrics ON analytics.artist_metrics(artist_id, period_start);

-- ==========================================
-- ANALYTICS.VENUE_METRICS
-- ==========================================
CREATE TABLE analytics.venue_metrics (
                                         id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                                         venue_id UUID NOT NULL REFERENCES profiles.venues(id),

                                         period_start DATE NOT NULL,
                                         period_end DATE NOT NULL,

                                         avg_attendance INT DEFAULT 0 CHECK (avg_attendance >= 0),
                                         total_events_count INT DEFAULT 0 CHECK (total_events_count >= 0),

                                         created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                         updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                                         CHECK (period_start <= period_end)
);

CREATE INDEX idx_venue_metrics ON analytics.venue_metrics(venue_id, period_start);

-- ==========================================
-- SCHEMA COMMENTS
-- ==========================================
COMMENT ON SCHEMA core IS 'Основная схема с пользователями и ролями';
COMMENT ON SCHEMA profiles IS 'Схема с профилями артистов и площадок';
COMMENT ON SCHEMA marketplace IS 'Схема для заявок, бронирований, сообщений и переписки';
COMMENT ON SCHEMA analytics IS 'Схема для аналитических данных: выступления и метрики';

-- ==========================================
-- CORE.USERS
-- ==========================================
COMMENT ON TABLE core.users IS 'Таблица пользователей системы';
COMMENT ON COLUMN core.users.id IS 'Уникальный идентификатор пользователя';
COMMENT ON COLUMN core.users.email IS 'Email пользователя';
COMMENT ON COLUMN core.users.password_hash IS 'Хэш пароля';
COMMENT ON COLUMN core.users.role IS 'Роль пользователя: artist, venue_owner, admin';
COMMENT ON COLUMN core.users.is_verified IS 'Флаг подтвержденного аккаунта';
COMMENT ON COLUMN core.users.is_active IS 'Флаг активного аккаунта';
COMMENT ON COLUMN core.users.created_at IS 'Дата и время создания пользователя';
COMMENT ON COLUMN core.users.updated_at IS 'Дата и время последнего обновления';
COMMENT ON COLUMN core.users.last_login_at IS 'Дата и время последнего входа пользователя';

-- ==========================================
-- PROFILES.ARTISTS
-- ==========================================
COMMENT ON TABLE profiles.artists IS 'Профили артистов';
COMMENT ON COLUMN profiles.artists.id IS 'Уникальный идентификатор артиста';
COMMENT ON COLUMN profiles.artists.user_id IS 'Ссылка на core.users';
COMMENT ON COLUMN profiles.artists.full_name IS 'Полное имя артиста';
COMMENT ON COLUMN profiles.artists.stage_name IS 'Сценическое имя артиста';
COMMENT ON COLUMN profiles.artists.bio IS 'Биография артиста';
COMMENT ON COLUMN profiles.artists.discography IS 'Дискография артиста';
COMMENT ON COLUMN profiles.artists.genre IS 'Основной жанр музыки';
COMMENT ON COLUMN profiles.artists.style IS 'Музыкальный стиль';
COMMENT ON COLUMN profiles.artists.music_links IS 'Ссылки на музыку (JSONB)';
COMMENT ON COLUMN profiles.artists.city IS 'Город проживания/деятельности';
COMMENT ON COLUMN profiles.artists.avg_audience_age IS 'Средний возраст аудитории';
COMMENT ON COLUMN profiles.artists.audience_profile IS 'Описание аудитории (JSONB)';
COMMENT ON COLUMN profiles.artists.performance_type IS 'Тип выступления';
COMMENT ON COLUMN profiles.artists.minimum_fee IS 'Минимальный гонорар за выступление';
COMMENT ON COLUMN profiles.artists.rider IS 'Технический райдер';
COMMENT ON COLUMN profiles.artists.contact_email IS 'Контактный email';
COMMENT ON COLUMN profiles.artists.contact_phone IS 'Контактный телефон';
COMMENT ON COLUMN profiles.artists.created_at IS 'Дата создания записи';
COMMENT ON COLUMN profiles.artists.updated_at IS 'Дата последнего обновления';

-- ==========================================
-- PROFILES.VENUES
-- ==========================================
COMMENT ON TABLE profiles.venues IS 'Профили площадок';
COMMENT ON COLUMN profiles.venues.id IS 'Уникальный идентификатор площадки';
COMMENT ON COLUMN profiles.venues.user_id IS 'Ссылка на core.users';
COMMENT ON COLUMN profiles.venues.name IS 'Название площадки';
COMMENT ON COLUMN profiles.venues.concept IS 'Концепция площадки';
COMMENT ON COLUMN profiles.venues.venue_type IS 'Тип площадки';
COMMENT ON COLUMN profiles.venues.capacity IS 'Вместимость';
COMMENT ON COLUMN profiles.venues.avg_ticket_price IS 'Средняя стоимость билета';
COMMENT ON COLUMN profiles.venues.address IS 'Адрес площадки';
COMMENT ON COLUMN profiles.venues.city IS 'Город расположения';
COMMENT ON COLUMN profiles.venues.work_schedule IS 'Рабочее расписание (JSONB)';
COMMENT ON COLUMN profiles.venues.avg_audience_age IS 'Средний возраст аудитории';
COMMENT ON COLUMN profiles.venues.audience_description IS 'Описание аудитории';
COMMENT ON COLUMN profiles.venues.preferred_genres IS 'Предпочитаемые музыкальные жанры (JSONB)';
COMMENT ON COLUMN profiles.venues.has_sound_system IS 'Наличие звуковой системы';
COMMENT ON COLUMN profiles.venues.has_stage IS 'Наличие сцены';
COMMENT ON COLUMN profiles.venues.has_lighting IS 'Наличие освещения';
COMMENT ON COLUMN profiles.venues.contact_email IS 'Контактный email';
COMMENT ON COLUMN profiles.venues.contact_phone IS 'Контактный телефон';
COMMENT ON COLUMN profiles.venues.photos_urls IS 'Ссылки на фотографии (JSONB)';
COMMENT ON COLUMN profiles.venues.created_at IS 'Дата создания записи';
COMMENT ON COLUMN profiles.venues.updated_at IS 'Дата последнего обновления';

-- ==========================================
-- MARKETPLACE.VENUE_REQUESTS
-- ==========================================
COMMENT ON TABLE marketplace.venue_requests IS 'Запросы площадок на артистов';
COMMENT ON COLUMN marketplace.venue_requests.id IS 'Уникальный идентификатор запроса';
COMMENT ON COLUMN marketplace.venue_requests.venue_id IS 'Ссылка на площадку';
COMMENT ON COLUMN marketplace.venue_requests.title IS 'Название запроса';
COMMENT ON COLUMN marketplace.venue_requests.description IS 'Описание запроса';
COMMENT ON COLUMN marketplace.venue_requests.event_date IS 'Дата мероприятия';
COMMENT ON COLUMN marketplace.venue_requests.budget_min IS 'Минимальный бюджет';
COMMENT ON COLUMN marketplace.venue_requests.budget_max IS 'Максимальный бюджет';
COMMENT ON COLUMN marketplace.venue_requests.required_genres IS 'Жанры, необходимые для выступления (JSONB)';
COMMENT ON COLUMN marketplace.venue_requests.performance_type IS 'Тип выступления';
COMMENT ON COLUMN marketplace.venue_requests.requirements IS 'Требования к артисту';
COMMENT ON COLUMN marketplace.venue_requests.equipment_provided IS 'Предоставляемое оборудование';
COMMENT ON COLUMN marketplace.venue_requests.status IS 'Статус запроса';
COMMENT ON COLUMN marketplace.venue_requests.created_at IS 'Дата создания записи';
COMMENT ON COLUMN marketplace.venue_requests.updated_at IS 'Дата последнего обновления';

-- ==========================================
-- MARKETPLACE.APPLICATIONS
-- ==========================================
COMMENT ON TABLE marketplace.applications IS 'Заявки артистов на запросы площадок';
COMMENT ON COLUMN marketplace.applications.id IS 'Уникальный идентификатор заявки';
COMMENT ON COLUMN marketplace.applications.artist_id IS 'Ссылка на артиста';
COMMENT ON COLUMN marketplace.applications.venue_id IS 'Ссылка на площадку';
COMMENT ON COLUMN marketplace.applications.venue_request_id IS 'Ссылка на запрос площадки';
COMMENT ON COLUMN marketplace.applications.proposed_date IS 'Предлагаемая дата выступления';
COMMENT ON COLUMN marketplace.applications.proposed_fee IS 'Предлагаемая сумма гонорара';
COMMENT ON COLUMN marketplace.applications.message IS 'Сообщение от артиста';
COMMENT ON COLUMN marketplace.applications.status IS 'Статус заявки';
COMMENT ON COLUMN marketplace.applications.created_at IS 'Дата создания записи';
COMMENT ON COLUMN marketplace.applications.updated_at IS 'Дата последнего обновления';

-- ==========================================
-- MARKETPLACE.CONVERSATIONS
-- ==========================================
COMMENT ON TABLE marketplace.conversations IS 'Разговоры между артистами и площадками';
COMMENT ON COLUMN marketplace.conversations.id IS 'Уникальный идентификатор разговора';
COMMENT ON COLUMN marketplace.conversations.artist_id IS 'Ссылка на артиста';
COMMENT ON COLUMN marketplace.conversations.venue_id IS 'Ссылка на площадку';
COMMENT ON COLUMN marketplace.conversations.application_id IS 'Ссылка на заявку';
COMMENT ON COLUMN marketplace.conversations.booking_id IS 'Ссылка на бронирование';
COMMENT ON COLUMN marketplace.conversations.created_at IS 'Дата создания разговора';

-- ==========================================
-- MARKETPLACE.MESSAGES
-- ==========================================
COMMENT ON TABLE marketplace.messages IS 'Сообщения внутри разговоров';
COMMENT ON COLUMN marketplace.messages.id IS 'Уникальный идентификатор сообщения';
COMMENT ON COLUMN marketplace.messages.conversation_id IS 'Ссылка на разговор';
COMMENT ON COLUMN marketplace.messages.sender_id IS 'Ссылка на отправителя (пользователя)';
COMMENT ON COLUMN marketplace.messages.message_text IS 'Текст сообщения';
COMMENT ON COLUMN marketplace.messages.is_read IS 'Флаг прочтения сообщения';
COMMENT ON COLUMN marketplace.messages.created_at IS 'Дата создания сообщения';

-- ==========================================
-- MARKETPLACE.BOOKINGS
-- ==========================================
COMMENT ON TABLE marketplace.bookings IS 'Бронирования артистов на запросы';
COMMENT ON COLUMN marketplace.bookings.id IS 'Уникальный идентификатор бронирования';
COMMENT ON COLUMN marketplace.bookings.application_id IS 'Ссылка на заявку';
COMMENT ON COLUMN marketplace.bookings.venue_request_id IS 'Ссылка на запрос площадки';
COMMENT ON COLUMN marketplace.bookings.artist_id IS 'Ссылка на артиста';
COMMENT ON COLUMN marketplace.bookings.venue_id IS 'Ссылка на площадку';
COMMENT ON COLUMN marketplace.bookings.event_date IS 'Дата события';
COMMENT ON COLUMN marketplace.bookings.agreed_fee IS 'Согласованный гонорар';
COMMENT ON COLUMN marketplace.bookings.platform_fee IS 'Комиссия платформы';
COMMENT ON COLUMN marketplace.bookings.status IS 'Статус бронирования';
COMMENT ON COLUMN marketplace.bookings.created_at IS 'Дата создания записи';
COMMENT ON COLUMN marketplace.bookings.updated_at IS 'Дата последнего обновления';

-- ==========================================
-- ANALYTICS.PERFORMANCES
-- ==========================================
COMMENT ON TABLE analytics.performances IS 'Данные о выступлениях';
COMMENT ON COLUMN analytics.performances.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN analytics.performances.artist_id IS 'Ссылка на артиста';
COMMENT ON COLUMN analytics.performances.venue_id IS 'Ссылка на площадку';
COMMENT ON COLUMN analytics.performances.event_date IS 'Дата выступления';
COMMENT ON COLUMN analytics.performances.attendance_count IS 'Количество посетителей';
COMMENT ON COLUMN analytics.performances.success_rating IS 'Оценка успеха выступления';
COMMENT ON COLUMN analytics.performances.created_at IS 'Дата создания записи';
COMMENT ON COLUMN analytics.performances.updated_at IS 'Дата последнего обновления';

-- ==========================================
-- ANALYTICS.ARTIST_METRICS
-- ==========================================
COMMENT ON TABLE analytics.artist_metrics IS 'Метрики артиста за период';
COMMENT ON COLUMN analytics.artist_metrics.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN analytics.artist_metrics.artist_id IS 'Ссылка на артиста';
COMMENT ON COLUMN analytics.artist_metrics.period_start IS 'Начало периода';
COMMENT ON COLUMN analytics.artist_metrics.period_end IS 'Конец периода';
COMMENT ON COLUMN analytics.artist_metrics.listens_total IS 'Количество прослушиваний';
COMMENT ON COLUMN analytics.artist_metrics.listeners_unique IS 'Количество уникальных слушателей';
COMMENT ON COLUMN analytics.artist_metrics.created_at IS 'Дата создания записи';
COMMENT ON COLUMN analytics.artist_metrics.updated_at IS 'Дата последнего обновления';

-- ==========================================
-- ANALYTICS.VENUE_METRICS
-- ==========================================
COMMENT ON TABLE analytics.venue_metrics IS 'Метрики площадки за период';
COMMENT ON COLUMN analytics.venue_metrics.id IS 'Уникальный идентификатор записи';
COMMENT ON COLUMN analytics.venue_metrics.venue_id IS 'Ссылка на площадку';
COMMENT ON COLUMN analytics.venue_metrics.period_start IS 'Начало периода';
COMMENT ON COLUMN analytics.venue_metrics.period_end IS 'Конец периода';
COMMENT ON COLUMN analytics.venue_metrics.avg_attendance IS 'Среднее количество посетителей';
COMMENT ON COLUMN analytics.venue_metrics.total_events_count IS 'Количество проведённых мероприятий';
COMMENT ON COLUMN analytics.venue_metrics.created_at IS 'Дата создания записи';
COMMENT ON COLUMN analytics.venue_metrics.updated_at IS 'Дата последнего обновления';