// lib/data/mock_events.dart
final List<Map<String, dynamic>> mockEvents = [
  {
    "id": "event1",
    "title": "Accessible Art Workshop",
    "description": "Join us for a creative art session designed for people with disabilities. All materials are provided.",
    "heldBy": "Community Art Center",
    "imageUrl": "https://images.unsplash.com/photo-1710294437659-c3706109b2cc?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    "date": "18-09-2025",
    "time": "10:00 AM - 12:00 PM",
    "location": "Community Art Center Hall",
    "registered": ["uid1","uid5"],
    "likes": ["uid1","uid2"],
    "favorites": ["uid3"],
    "upvotes": ["uid1","uid2"],
    "comments": [
      {
        "id": "comment1",
        "userId": "uid1",
        "userName": "John Doe",
        "text": "น่าสนใจมากครับ! อยากเข้าร่วม",
        "timestamp": "2024-09-15 10:30:00",
        "profileImage": "https://images.unsplash.com/photo-1626548307930-deac221f87d9?q=80&w=1068&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
      },
      {
        "id": "comment2",
        "userId": "uid2",
        "userName": "Jane Smith",
        "text": "มีอุปกรณ์สำหรับผู้พิการทางสายตาหรือไม่ครับ?",
        "timestamp": "2024-09-15 11:15:00",
        "profileImage": "https://images.unsplash.com/photo-1726107866473-383d3e90e74d?q=80&w=1750&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
      }
    ]
  },
  {
    "id": "event2",
    "title": "Inclusive Sports Day",
    "description": "Come join our inclusive sports event! Adapted games and activities for people with various disabilities.",
    "heldBy": "Able Sports Club",
    "imageUrl": "https://images.unsplash.com/photo-1685541000777-8d0995d38909?q=80&w=2062&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    "date": "22-06-2025",
    "time": "09:00 AM - 03:00 PM",
    "location": "Able Sports Club Stadium",
    "registered": ["uid3","uid6"],
    "likes": ["uid3","uid4"],
    "favorites": ["uid2"],
    "upvotes": ["uid4","uid5"],
    "comments": [
      {
        "id": "comment3",
        "userId": "uid3",
        "userName": "Mike Johnson",
        "text": "กิจกรรมดีมาก! ครอบครัวของผมจะไปร่วมแน่นอน",
        "timestamp": "2024-01-16 09:20:00",
        "profileImage": "https://images.unsplash.com/photo-1571635701965-a38724d85f34?q=80&w=1748&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
      }
    ]
  }
];
