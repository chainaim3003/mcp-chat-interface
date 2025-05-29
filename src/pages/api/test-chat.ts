// Test endpoint to verify chat processing
import { NextApiRequest, NextApiResponse } from 'next';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  console.log('🧪 TEST CHAT API CALLED');
  console.log('Method:', req.method);
  console.log('Body:', req.body);
  
  res.json({
    success: true,
    message: "TEST: Dynamic API is working!",
    timestamp: new Date().toISOString(),
    body: req.body
  });
}
