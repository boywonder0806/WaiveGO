// Thin client for the Smartwaiver API (v4). Docs: https://api.smartwaiver.com/docs/v4/
// Auth is a Bearer token tied to a "published key" generated in the Smartwaiver
// console — see .env.example for where it's configured.

import { config } from "../config";

export interface SmartwaiverWaiver {
  waiverId: string;
  templateId: string;
  title: string;
  createdOn: string;
  expirationDate: string | null;
  expired: boolean;
  verified: boolean;
  firstName: string;
  lastName: string;
  email?: string;
  participants: Array<{
    firstName: string;
    lastName: string;
    dob: string;
    isMinor: boolean;
  }>;
}

interface SmartwaiverWaiverResponse {
  waiver: SmartwaiverWaiver;
}

export async function getWaiver(waiverId: string): Promise<SmartwaiverWaiver> {
  const response = await fetch(`${config.smartwaiver.baseUrl}/v4/waivers/${waiverId}`, {
    headers: { Authorization: `Bearer ${config.smartwaiver.apiKey}` },
  });

  if (!response.ok) {
    throw new Error(`Smartwaiver getWaiver(${waiverId}) failed: ${response.status} ${await response.text()}`);
  }

  const data = (await response.json()) as SmartwaiverWaiverResponse;
  return data.waiver;
}
