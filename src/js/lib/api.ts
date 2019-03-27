import * as firebase from 'firebase/app';
import 'firebase/database';
import { Item } from '../@types';

firebase.initializeApp({
  databaseURL: 'https://hacker-news.firebaseio.com',
});

const databaseRef = firebase.database().ref('/v0');

function itemsWithInfo(items: number[]): Promise<Item[]> {
  const promises: Promise<Item>[] = items.map(async (item: number) => {
    const itemRef = databaseRef.child(`/item/${item}`);
    const itemSnapshot = await itemRef.once('value');
    const itemValue: Item = itemSnapshot.val();

    return itemValue;
  });

  return Promise.all(promises);
}

export async function getPost(id: number): Promise<Item> {
  const itemRef = databaseRef.child(`/item/${id}`);
  const itemSnapshot = await itemRef.once('value');
  const itemValue: Item = itemSnapshot.val();

  return itemValue;
}

export async function getTopStories(): Promise<Item[]> {
  const ref = databaseRef.child('/topstories');
  const snapshot = await ref.once('value');
  const storiesRef = snapshot.val();
  const storiesWithInfo: Item[] = await itemsWithInfo(storiesRef);

  return storiesWithInfo;
}

export async function getNewStories(): Promise<Item[]> {
  const ref = databaseRef.child('/newstories');
  const snapshot = await ref.once('value');
  const storiesRef = snapshot.val();
  const storiesWithInfo: Item[] = await itemsWithInfo(storiesRef);

  return storiesWithInfo;
}

export async function getBestStories(): Promise<Item[]> {
  const ref = databaseRef.child('/beststories');
  const snapshot = await ref.once('value');
  const storiesRef = snapshot.val();
  const storiesWithInfo: Item[] = await itemsWithInfo(storiesRef);

  return storiesWithInfo;
}

export async function getComments(id: number): Promise<Item[]> {
  const ref = databaseRef.child(`/item/${id}`);
  const snapshot = await ref.once('value');
  const { kids = [] }: { kids: number[] } = snapshot.val();
  const comments = await travelKids(kids);

  return comments;
}

async function travelKids(ids: number[]): Promise<Item[]> {
  if (ids && ids.length) {
    const items = await itemsWithInfo(ids);
    return Promise.all(
      items.map(async ({ kids, ...rest }) => {
        return {
          ...rest,
          kids: await travelKids(kids as number[]),
        };
      }),
    );
  }
  return Promise.resolve([]);
}
