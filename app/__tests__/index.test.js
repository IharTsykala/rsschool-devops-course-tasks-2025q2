import request from 'supertest';
import app from '../index.js';

describe('GET /', () => {
	it('should return Hello, World from Node.js!', async () => {
		const res = await request(app).get('/');
		expect(res.statusCode).toBe(200);
		expect(res.text).toBe('Hello, World from Node.js!');
	});
});
