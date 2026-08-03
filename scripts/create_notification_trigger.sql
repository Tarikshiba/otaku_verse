-- Active l'extension pg_net (pour faire des appels HTTP depuis SQL)
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Fonction trigger : appelle l'Edge Function quand une demande d'ami est inseree
CREATE OR REPLACE FUNCTION notify_friend_request()
RETURNS trigger AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://houbjgugzznytilkfwyf.supabase.co/functions/v1/envoyer-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('supabase.service_role_key', true)
    ),
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'friends',
      'record', jsonb_build_object(
        'sender_id', NEW.sender_id,
        'receiver_id', NEW.receiver_id,
        'status', NEW.status
      )
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger : se declenche apres chaque INSERT dans friends
DROP TRIGGER IF EXISTS on_friend_request_inserted ON friends;
CREATE TRIGGER on_friend_request_inserted
  AFTER INSERT ON friends
  FOR EACH ROW
  EXECUTE FUNCTION notify_friend_request();
