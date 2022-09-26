CREATE TABLE raw_comments
-- Comments as they come off the Reddit API with no attempt at normalization
(
    thread_id                       TEXT    NOT NULL,
    thread_created_utc              INTEGER NOT NULL,
    id                              TEXT PRIMARY KEY,
    created_utc                     INTEGER NOT NULL,
    author                          TEXT    NOT NULL,
    parent_id                       TEXT,
    body                            TEXT    NOT NULL DEFAULT '',
    all_awardings                   TEXT,
    approved_at_utc                 INTEGER,
    associated_award                TEXT,
    author_flair_background_color   TEXT,
    author_flair_css_class          TEXT,
    author_flair_richtext           TEXT,
    author_flair_template_id        TEXT,
    author_flair_text               TEXT,
    author_flair_text_color         TEXT,
    author_flair_type               TEXT,
    author_fullname                 TEXT,
    author_patreon_flair            TEXT,
    author_premium                  TEXT,
    awarders                        TEXT,
    banned_at_utc                   TEXT,
    can_mod_post                    TEXT,
    collapsed                       TEXT,
    collapsed_because_crowd_control TEXT,
    collapsed_reason                TEXT,
    comment_type                    TEXT,
    distinguished                   TEXT,
    edited                          TEXT,
    gildings                        TEXT,
    is_submitter                    TEXT,
    link_id                         TEXT,
    locked                          TEXT,
    no_follow                       TEXT,
    permalink                       TEXT,
    retrieved_on                    TEXT,
    score                           INT     NOT NULL DEFAULT 0,
    send_replies                    TEXT,
    stickied                        TEXT,
    subreddit                       TEXT,
    subreddit_id                    TEXT,
    top_awarded_type                TEXT,
    total_awards_received           TEXT,
    treatment_tags                  TEXT
);
--;;
CREATE INDEX raw_comments_parent_id ON raw_comments (parent_id);
--;;
CREATE MATERIALIZED VIEW answers AS
WITH RECURSIVE answers_cte AS (SELECT parent.id                 AS question_id,
                                      child.id                  AS answer_id,
                                      child.parent_id           AS answer_parent_id,
                                      parent.body               AS question_text,
                                      child.body                AS answer_text,
                                      parent.author             AS question_author,
                                      child.author              AS answer_author,
                                      parent.score              AS question_score,
                                      child.score               AS answer_score,
                                      parent.permalink          AS question_permalink,
                                      child.permalink           AS answer_permalink,
                                      parent.thread_id          AS thread_id,
                                      parent.thread_created_utc AS thread_created_utc
                               FROM raw_comments AS child
                                        INNER JOIN raw_comments parent ON child.parent_id = parent.id
                               WHERE parent.parent_id IS NULL
                               UNION
                               SELECT parent.question_id        AS question_id,
                                      child.id                  AS answer_id,
                                      child.parent_id           AS answer_parent_id,
                                      parent.question_text      AS question_text,
                                      child.body                AS answer_text,
                                      parent.question_author    AS question_author,
                                      child.author              AS answer_author,
                                      parent.question_score     AS question_score,
                                      child.score               AS answer_score,
                                      parent.question_permalink AS question_permalink,
                                      child.permalink           AS answer_permalink,
                                      parent.thread_id          AS thread_id,
                                      parent.thread_created_utc AS thread_created_utc
                               FROM raw_comments AS child
                                        INNER JOIN answers_cte parent ON child.parent_id = parent.answer_id)
SELECT *
FROM answers_cte;
--;;
CREATE UNIQUE INDEX answers_id_ix ON answers (question_id, answer_id);
--;;
CREATE INDEX answers_created ON answers (thread_created_utc);
--;;
CREATE INDEX answers_textsearch ON answers USING GIN (to_tsvector('english', question_text || ' ' || answer_text));
--;;
CREATE OR REPLACE FUNCTION text_search(query TEXT)
    RETURNS TABLE
            (
                question_id        TEXT,
                relevance          FLOAT4,
                question_text      TEXT,
                question_author    TEXT,
                question_score     INTEGER,
                question_permalink TEXT,
                thread_id          TEXT,
                thread_created_utc INTEGER
            )
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN QUERY
        SELECT answers.question_id,
               max(ts_rank_cd(to_tsvector('english', answers.question_text || ' ' || answers.answer_text),
                              plainto_tsquery('english', query))) AS relevance,
               answers.question_text,
               answers.question_author,
               answers.question_score,
               answers.question_permalink,
               answers.thread_id,
               answers.thread_created_utc
        FROM answers
        WHERE to_tsvector('english', answers.question_text || ' ' || answers.answer_text) @@
              plainto_tsquery('english', query)
        GROUP BY answers.question_id,
                 answers.question_author,
                 answers.question_score,
                 answers.question_text,
                 answers.question_permalink,
                 answers.thread_id,
                 answers.thread_created_utc
        ORDER BY relevance DESC
        LIMIT 10;
END;
$$;