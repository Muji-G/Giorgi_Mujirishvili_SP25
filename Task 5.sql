CREATE OR REPLACE FUNCTION public.new_movie(
    p_title TEXT,
    p_release_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    p_language TEXT DEFAULT 'Klingon')
RETURNS VOID AS $$
DECLARE
    v_lang_id INTEGER;
    v_exists BOOLEAN;
BEGIN
    -- By this query I check that the language exists in the language table
    SELECT language_id INTO v_lang_id
    FROM language
    WHERE name = p_language;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Language % does not exist in language table.', p_language;
    END IF;

    -- By this query I check if the movie already exists
    SELECT EXISTS (
        SELECT 1 FROM film WHERE title = p_title
    ) INTO v_exists;

    IF v_exists THEN
        RAISE EXCEPTION 'Film % already exists.', p_title;
    END IF;

    -- By this I insert the new movie with default attributes
    INSERT INTO film (title, release_year, language_id, rental_duration, rental_rate, replacement_cost)
    VALUES (p_title, p_release_year, v_lang_id, 3, 4.99, 19.99);

    RAISE NOTICE 'Film % successfully added.', p_title;
END;
$$ LANGUAGE plpgsql;

