-- =========================================================
-- V1__init.sql : 初期スキーマ（users / posts）
-- =========================================================
-- 前提：
--   - public スキーマを使用（デフォルト）
--   - IDは BIGSERIAL（Java側は Long + GenerationType.IDENTITY）
--   - created_at / updated_at は timestamptz
--   - updated_at は UPDATE 時に自動更新（トリガー）
-- =========================================================

-- 1) タイムスタンプ更新用のトリガー関数（共通）
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2) users テーブル
CREATE TABLE users (
  id           BIGSERIAL PRIMARY KEY,
  username     VARCHAR(30)  NOT NULL,
  -- 必要に応じてメールやパスワードハッシュを将来追加できます:
  -- email        VARCHAR(255),
  -- password_hash VARCHAR(255),

  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_users_username UNIQUE (username),
  CONSTRAINT ck_users_username_len CHECK (char_length(username) BETWEEN 1 AND 30)
);

-- updated_at 自動更新トリガー
CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 3) posts テーブル
CREATE TABLE posts (
  id           BIGSERIAL PRIMARY KEY,
  user_id      BIGINT       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content      TEXT         NOT NULL,

  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- 投稿の検索を想定：ユーザー別の新着順を取りやすくする
CREATE INDEX idx_posts_user_created_at ON posts (user_id, created_at DESC);

-- updated_at 自動更新トリガー
CREATE TRIGGER trg_posts_updated_at
BEFORE UPDATE ON posts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 4) 参考：将来スキーマを分けたい場合（例：sns）
-- CREATE SCHEMA IF NOT EXISTS sns AUTHORIZATION CURRENT_USER;
-- ALTER DATABASE CURRENT_DATABASE() SET search_path TO sns, public;
-- ※ 使うなら @Table(schema="sns") / default_schema を合わせる
