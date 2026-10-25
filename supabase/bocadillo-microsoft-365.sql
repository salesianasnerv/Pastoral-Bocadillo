-- Bocadillo solidario · entrar con Microsoft 365 (25-10-2026). PEDIR VISTO BUENO A MARIÁN ANTES.
-- Ejecutar en Supabase → SQL Editor, proyecto «Acceso Microsoft 365». Se puede volver a ejecutar.
--
-- La web del Bocadillo guarda los datos en una hoja de Google (Apps Script). Desde ahora, el Apps Script pregunta
-- a esta función quién ha iniciado sesión y qué puede hacer:
--   · pastoral = está en el grupo «Pastoral» de Microsoft 365 (e-ner-pastoral, sincronizado cada noche):
--                entra en el panel de Pastoral y puede rellenar el recuento de cualquier clase.
--   · tutorias = grupos de los que es tutor/a en el curso activo (lista común, pestaña «Tutorías» del panel):
--                solo puede rellenar el recuento de esas clases.
-- Solo devuelve el nombre de la persona y los nombres de sus grupos (ningún dato del alumnado).

begin;

create or replace function boc_quien_soy() returns jsonb
language sql stable security definer set search_path = public as $$
  select case when not es_profesorado() then null else jsonb_build_object(
    'email',    p.email,
    'nombre',   p.nombre,
    'pastoral', coalesce('pastoral' = any(p.grupos_entra), false),
    'tutorias', coalesce((select jsonb_agg(jsonb_build_object('nombre', g.nombre, 'etapa', g.etapa) order by g.orden)
                          from grupos g join cursos c on c.id = g.curso_id and c.activo
                          where lower(g.tutor_email) = lower(p.email::text)), '[]'::jsonb))
  end
  from personal p where p.email = email_actual() and p.activo
$$;
revoke execute on function boc_quien_soy() from public, anon;
grant execute on function boc_quien_soy() to authenticated;

commit;

-- Comprobación: quién está hoy en el grupo Pastoral (tienen que salir las personas de Pastoral)
select nombre, email from personal where activo and 'pastoral' = any(grupos_entra) order by nombre;
