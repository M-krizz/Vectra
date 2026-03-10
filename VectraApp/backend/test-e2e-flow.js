#!/usr/bin/env node

/**
 * Live API E2E flow verifier for Vectra backend.
 *
 * Covers:
 * 1) Rider OTP login
 * 2) Ride request create/current/cancel
 * 3) Rider incident report (ride-linked)
 * 4) Rider SOS trigger
 * 4) Admin OTP login
 * 5) Admin incident list/escalate/resolve
 * 6) Rider emergency contacts CRUD
 * 7) Driver OTP login (ensures pending profile exists)
 * 8) Admin metrics and pending drivers endpoints
 * 9) Admin driver approval status update
 */

const BASE_URL = process.env.API_BASE_URL || 'http://127.0.0.1:3000';
const OTP_CODE = process.env.E2E_OTP_CODE || '000000';

async function request(path, options = {}) {
  const headers = {
    'content-type': 'application/json',
    ...(options.headers || {}),
  };

  const response = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers,
  });

  let body = null;
  try {
    body = await response.json();
  } catch {
    body = null;
  }

  return { status: response.status, body };
}

function assertStatus(label, actual, expected) {
  const ok = actual === expected;
  console.log(`${ok ? 'PASS' : 'FAIL'} ${label}: ${actual} (expected ${expected})`);
  if (!ok) {
    process.exitCode = 1;
  }
}

async function main() {
  console.log('Running Vectra live E2E flow...');
  console.log(`Base URL: ${BASE_URL}`);

  const riderLogin = await request('/api/v1/auth/verify-otp', {
    method: 'POST',
    headers: { 'x-role-hint': 'RIDER' },
    body: JSON.stringify({
      identifier: 'rider.e2e@vectra.local',
      code: OTP_CODE,
    }),
  });
  assertStatus('rider verify-otp', riderLogin.status, 201);
  const riderToken = riderLogin.body?.accessToken;
  if (!riderToken) {
    console.log('FAIL rider access token missing');
    process.exit(1);
  }

  const createRequest = await request('/api/v1/ride-requests', {
    method: 'POST',
    headers: { Authorization: `Bearer ${riderToken}` },
    body: JSON.stringify({
      pickupPoint: { type: 'Point', coordinates: [80.2707, 13.0827] },
      dropPoint: { type: 'Point', coordinates: [80.24, 13.06] },
      pickupAddress: 'Chennai Central',
      dropAddress: 'Marina Beach',
      rideType: 'SOLO',
      vehicleType: 'AUTO',
    }),
  });
  assertStatus('ride-requests create', createRequest.status, 201);
  const rideRequestId = createRequest.body?.id;
  if (!rideRequestId) {
    console.log('FAIL ride request id missing');
    process.exit(1);
  }

  const currentRequest = await request('/api/v1/ride-requests/current', {
    headers: { Authorization: `Bearer ${riderToken}` },
  });
  assertStatus('ride-requests current', currentRequest.status, 200);

  const cancelRequest = await request(`/api/v1/ride-requests/${rideRequestId}/cancel`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${riderToken}` },
  });
  assertStatus('ride-requests cancel', cancelRequest.status, 200);

  const incidentReport = await request('/api/v1/safety/incidents', {
    method: 'POST',
    headers: { Authorization: `Bearer ${riderToken}` },
    body: JSON.stringify({
      description: 'E2E ride-linked incident',
      rideId: rideRequestId,
    }),
  });
  assertStatus('safety incident report', incidentReport.status, 201);
  const reportedIncidentId = incidentReport.body?.id;
  if (!reportedIncidentId) {
    console.log('FAIL reported incident id missing');
    process.exit(1);
  }

  const sos = await request('/api/v1/safety/sos', {
    method: 'POST',
    headers: { Authorization: `Bearer ${riderToken}` },
    body: JSON.stringify({ lat: 13.0827, lng: 80.2707 }),
  });
  assertStatus('safety sos', sos.status, 201);
  const incidentId = sos.body?.id;
  if (!incidentId) {
    console.log('FAIL incident id missing');
    process.exit(1);
  }

  const adminLogin = await request('/api/v1/auth/verify-otp', {
    method: 'POST',
    headers: { 'x-role-hint': 'ADMIN' },
    body: JSON.stringify({
      identifier: 'admin.e2e@vectra.local',
      code: OTP_CODE,
    }),
  });
  assertStatus('admin verify-otp', adminLogin.status, 201);
  const adminToken = adminLogin.body?.accessToken;
  if (!adminToken) {
    console.log('FAIL admin access token missing');
    process.exit(1);
  }

  const incidents = await request('/api/v1/safety/incidents', {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  assertStatus('safety incidents list', incidents.status, 200);

  const incidentDetail = await request(`/api/v1/safety/incidents/${reportedIncidentId}`, {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  assertStatus('safety incident detail', incidentDetail.status, 200);

  const escalate = await request(`/api/v1/safety/incidents/${incidentId}/escalate`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${adminToken}` },
    body: JSON.stringify({ note: 'e2e escalation' }),
  });
  assertStatus('safety incident escalate', escalate.status, 200);

  const resolve = await request(`/api/v1/safety/incidents/${incidentId}/resolve`, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${adminToken}` },
    body: JSON.stringify({ resolution: 'e2e resolved' }),
  });
  assertStatus('safety incident resolve', resolve.status, 200);

  const addContact = await request('/api/v1/safety/contacts', {
    method: 'POST',
    headers: { Authorization: `Bearer ${riderToken}` },
    body: JSON.stringify({
      name: 'E2E Contact',
      phoneNumber: '+919900000001',
      relationship: 'Friend',
    }),
  });
  assertStatus('safety contacts add', addContact.status, 201);
  const contactId = addContact.body?.id;
  if (!contactId) {
    console.log('FAIL contact id missing');
    process.exit(1);
  }

  const listContacts = await request('/api/v1/safety/contacts', {
    headers: { Authorization: `Bearer ${riderToken}` },
  });
  assertStatus('safety contacts list', listContacts.status, 200);

  const deleteContact = await request(`/api/v1/safety/contacts/${contactId}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${riderToken}` },
  });
  assertStatus('safety contacts delete', deleteContact.status, 200);

  const driverLogin = await request('/api/v1/auth/verify-otp', {
    method: 'POST',
    headers: { 'x-role-hint': 'DRIVER' },
    body: JSON.stringify({
      identifier: 'driver.e2e@vectra.local',
      code: OTP_CODE,
    }),
  });
  assertStatus('driver verify-otp', driverLogin.status, 201);

  const metrics = await request('/api/v1/admin/metrics/overview', {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  assertStatus('admin metrics overview', metrics.status, 200);

  const pendingDrivers = await request('/api/v1/admin/drivers/pending', {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  assertStatus('admin drivers pending', pendingDrivers.status, 200);

  const pendingList = Array.isArray(pendingDrivers.body) ? pendingDrivers.body : [];
  if (pendingList.length > 0) {
    const targetProfileId = pendingList[0]?.id;
    const updateDriverStatus = await request(
      `/api/v1/admin/drivers/${targetProfileId}/status`,
      {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${adminToken}` },
        body: JSON.stringify({ status: 'APPROVED' }),
      },
    );
    assertStatus('admin drivers status update', updateDriverStatus.status, 200);
  } else {
    console.log('FAIL admin drivers status update: no pending driver profiles available');
    process.exitCode = 1;
  }

  if (process.exitCode && process.exitCode !== 0) {
    console.log('E2E flow finished with failures.');
    return;
  }

  console.log('E2E flow completed successfully.');
}

main().catch((error) => {
  console.error('Unhandled error during E2E flow:', error);
  process.exit(1);
});