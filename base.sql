INSERT INTO ps_auths (id, auth_type, username, password)
VALUES
('1001', 'userpass', '1001', 'Password1001'),
('1002', 'userpass', '1002', 'Password1002');

INSERT INTO ps_aors (id, max_contacts, remove_existing)
VALUES
('1001', 5, 'yes'),
('1002', 5, 'yes');

INSERT INTO ps_endpoints (
    id,
    transport,
    aors,
    auth,
    context,
    from_domain,
    disallow,
    allow,
    webrtc,
    use_avpf,
    media_encryption,
    dtls_verify,
    dtls_setup,
    ice_support,
    rtcp_mux,
    rewrite_contact,
    force_rport,
    rtp_symmetric,
    direct_media
)
VALUES
(
    '1001',
    'transport-wss',
    '1001',
    '1001',
    'from-internal',
    'localhost',
    'all',
    'opus,ulaw',
    'yes',
    'yes',
    'dtls',
    'fingerprint',
    'actpass',
    'yes',
    'yes',
    'yes',
    'yes',
    'yes',
    'no'
),
(
    '1002',
    'transport-wss',
    '1002',
    '1002',
    'from-internal',
    'localhost',
    'all',
    'opus,ulaw',
    'yes',
    'yes',
    'dtls',
    'fingerprint',
    'actpass',
    'yes',
    'yes',
    'yes',
    'yes',
    'yes',
    'no'
);