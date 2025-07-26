import express from 'express';

const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
	res.send('Hello, World from Node.js!');
});

if (process.env.NODE_ENV !== 'test') {
	app.listen(PORT, () => {
		console.log(`Server is listening on port ${PORT}`);
	});
}

export default app;
